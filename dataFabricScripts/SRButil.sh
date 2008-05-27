#!/bin/bash
#
# this script requires sudo access for the srb user. Add:
# srb     srb.ivec.org=NOPASSWD: /sbin/service srb stop, /sbin/service srb start, /sbin/service srb restart
# to /etc/sudoers
#
if [[ !$SRBROOT ]]; then
	export SRBROOT=/usr/srb
fi

if [[ !$SRBHOME ]]; then
	export SRBHOME=/var/lib/srb
fi

if [[ !$MCATDATA ]]; then
	export MCATDATA=$SRBHOME/mcat
fi

if [[ !$BACKUPROOT ]]; then
	export BACKUPROOT=/var/lib/srb/pbstore-backup
fi

if [[ !$HOSTKEY ]]; then
	export HOSTKEY=$SRBHOME/hostkey.pem
fi

if [[ !$HOSTCERT ]]; then
	export HOSTCERT=$SRBHOME/hostcert.pem
fi

# list of vault locations to be backed up
VAULTS=(/var/lib/srb/Vault /var/lib/srb/pbstore-vault)

# settings for the remote backup
export remoteBackupZone=ngdev2.its.utas.edu.au
export remoteBackupResource=data_fabric
export srbAdminUser=srbAdmin
export srbAdminDomain=srb.ivec.org

export NOW=`date +%Y%m%d%H%M`
export PAST=`date --date "now -2 days" +%Y-%m-%d-%H.%M`
export HOST=`uname -n`

stopSRB () {
	sudo /sbin/service srb stop
	return $?
}

startSRB () {
	sudo /sbin/service srb start
	return $?
}

backup () {
	stopSRB
	echo "Backing up SRB configuration and Database..."
	tar -cpPf /tmp/$1.tar $MCATDATA/
	tar -rpPf /tmp/$1.tar $SRBHOME/.srb/
	tar -rpPf /tmp/$1.tar $HOSTCERT
	tar -rpPf /tmp/$1.tar $HOSTKEY
	tar -rpPf /tmp/$1.tar $SRBHOME/.odbc.ini
	tar -rpPf /tmp/$1.tar $SRBROOT/bin/runsrb
	tar -rpPf /tmp/$1.tar $SRBROOT/data/host*
	tar -rpPf /tmp/$1.tar $SRBROOT/data/mcatHost
	tar -rpPf /tmp/$1.tar $SRBROOT/data/MdasConfig
	tar -rpPf /tmp/$1.tar $SRBROOT/data/shibConfig
	tar -rpPf /tmp/$1.tar $SRBROOT/globus/etc/gridftp_srb.conf
	echo "done."
	if [ $2 -eq 2 ]; then
		for vault in ${VAULTS[@]}; do
			vaultName=`echo $vault | grep -oe  '[a-zA-Z0-9_-]*$'`
			echo "Backing up $vault..."
			tar -cpPf /tmp/$1-$vaultName.tar $vault/
			mv /tmp/$1-$vaultName.tar $BACKUPROOT/
			echo 'done.'
		done 
	fi
	startSRB
	if [ $2 -eq 1 ]; then
		echo "Running remote backup..."
		/usr/bin/Sinit
		/usr/bin/Scd /$remoteBackupZone/home/$srbAdminUser.$srbAdminDomain
		/usr/bin/Sput -S $remoteBackupResource  /tmp/$1.tar
		/usr/bin/Sexit
		echo "done."
	fi
	mv /tmp/$1.tar $BACKUPROOT/
	return $?
}

restore () {
	stopSRB
	if test -f $1; then
		tar -xpPf $1
		if [ $? -eq 0 ]; then
			startSRB
		fi
		return $?
	fi
		return 1
}

cleanOld () {
	echo "Cleaning old local backups..."
	find $BACKUPROOT -mtime +2 | xargs rm -rf
	echo "done."
	if [ $1 -eq 1 ]; then
		echo "Cleaning old remote backups..."
		/usr/bin/Sinit
		/usr/bin/Srm -A "CTIME < $PAST"-rf /$remoteBackupZone/home/$srbAdminUser.$srbAdminDomain/*
		/usr/bin/Sexit
		echo "done."
	fi	
	return $?
}

case "$1" in
	backup)
		case "$2" in
			remote)
				backup srb-backup-$HOST-$NOW 1
				;;
			data)
				backup srb-backup-$HOST-$NOW 2
				;;
			*)
				backup srb-backup-$HOST-$NOW 0
				;;
		esac
		;;
	restore)
		restore $2 
		;;
	clean)
		case "$2" in
			remote)
				cleanOld 1 
				;;
			*)
				cleanOld 0
				;;
		esac
		;;
*)
	echo $"Usage: $0 {backup [remote] | restore <ARCHIVE> | clean [remote]}"
	exit 1
esac

exit $?

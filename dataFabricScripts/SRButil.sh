#!/bin/bash

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
	export BACKUPROOT=/pbstore/srb-vault/backups/
fi

if [[ !$HOSTKEY ]]; then
	export HOSTKEY=$SRBHOME/hostkey.pem
fi

if [[ !$HOSTCERT ]]; then
	export HOSTCERT=$SRBHOME/hostcert.pem
fi

export remoteBackupZone=ngdev2.its.utas.edu.au
export remoteBackupResource=data_fabric
export srbAdminUser=srbAdmin
export srbAdminDomain=srb.ivec.org

export NOW=`date +%Y%m%d%H%M`
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
	tar -cpPf /tmp/$1 $MCATDATA/
	tar -rpPf /tmp/$1 $SRBHOME/.srb/
	tar -rpPf /tmp/$1 $HOSTCERT
	tar -rpPf /tmp/$1 $HOSTKEY
	tar -rpPf /tmp/$1 $SRBHOME/.odbc.ini
	tar -rpPf /tmp/$1 $SRBROOT/bin/runsrb
	tar -rpPf /tmp/$1 $SRBROOT/data/host*
	tar -rpPf /tmp/$1 $SRBROOT/data/mcatHost
	tar -rpPf /tmp/$1 $SRBROOT/data/MdasConfig
	tar -rpPf /tmp/$1 $SRBROOT/data/shibConfig
	tar -rpPf /tmp/$1 $SRBROOT/globus/etc/gridftp_srb.conf
	startSRB
	if [ $2 -eq 1 ]; then
		/usr/bin/Sinit
		/usr/bin/Scd /$remoteBackupZone/home/$srbAdminUser.$srbAdminDomain
		/usr/bin/Sput -S $remoteBackupResource  /tmp/$1
		/usr/bin/Sexit
	fi
	mv /tmp/$1 $BACKUPROOT/
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

case "$1" in
	backup)
		case "$2" in
			remote)
				backup srb-backup-$HOST-$NOW.tar 1
				;;
			*)
				backup srb-backup-$HOST-$NOW.tar 0
				;;
		esac
		;;
	restore)
		restore $2 srb-backup-$HOST-$NOW-before_restore.tar
		;;
*)
	echo $"Usage: $0 {backup [remote] |restore <ARCHIVE>}"
	exit 1
esac

exit $?

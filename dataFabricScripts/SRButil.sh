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

export remoteBackupZone=srb-dev.ivec.org
export remoteBackupResource=srb-dev.ivec.org
export srbAdminUser=srbAdmin
export srbAdminDomain=srb.ivec.org

export NOW=`date +%Y%m%d%k%M`
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
	tar -cpPf $1 $MCATDATA/
	tar -rpPf $1 $SRBHOME/.srb/
	tar -rpPf $1 $HOSTCERT
	tar -rpPf $1 $HOSTKEY
	tar -rpPf $1 $SRBHOME/.odbc.ini
	tar -rpPf $1 $SRBROOT/bin/runsrb
	tar -rpPf $1 $SRBROOT/data/host*
	tar -rpPf $1 $SRBROOT/data/mcatHost
	tar -rpPf $1 $SRBROOT/data/MdasConfig
	tar -rpPf $1 $SRBROOT/data/shibConfig
	tar -rpPf $1 $SRBROOT/globus/etc/gridftp_srb.conf
	startSRB
	/usr/bin/Sinit
	/usr/bin/Scd /$remoteBackupZone/home/$srbAdminUser.$srbAdminDomain
	/usr/bin/Sput -S $remoteBackupResource  $1
	/usr/bin/Sexit
	mv $1 $BACKUPROOT/
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
		backup srb-backup-$HOST-$NOW.tar
		;;
	restore)
		restore $2 srb-backup-$HOST-$NOW-before_restore.tar
		;;
*)
	echo $"Usage: $0 {backup|restore <ARCHIVE>}"
	exit 1
esac

exit $?

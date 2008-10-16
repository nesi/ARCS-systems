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
	export BACKUPROOT=./backup
fi

if [[ !$HOSTKEY ]]; then
	export HOSTKEY=$SRBHOME/hostkey.pem
fi

if [[ !$HOSTCERT ]]; then
	export HOSTCERT=$SRBHOME/hostcert.pem
fi

if [[ !$TIME_TO_KEEP ]]; then
	export TIME_TO_KEEP=60
fi

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
	#stopSRB
	#tar -cpPf $1 $MCATDATA/
	pg_dump -o -f $SRBHOME/MCAT.dump MCAT
	tar -rpPf $1 $SRBHOME/MCAT.dump
	tar -rpPf $1 $SRBHOME/.srb/
	tar -rpPf $1 $HOSTCERT
	tar -rpPf $1 $HOSTKEY
	tar -rpPf $1 $SRBHOME/.odbc.ini
	tar -rpPf $1 $SRBROOT/bin/runsrb
	tar -rpPf $1 $SRBROOT/data/host*
	tar -rpPf $1 $SRBROOT/data/mcatHost
	tar -rpPf $1 $SRBROOT/data/MdasConfig
	tar -rpPf $1 $SRBROOT/data/shibConfig
	if test -f $SRBROOT/globus/etc/gridftp_srb.conf; then
		tar -rpPf $1 $SRBROOT/globus/etc/gridftp_srb.conf
	fi
	#startSRB
	rm $SRBHOME/MCAT.dump
	echo 'moving tar ball...'
	mv $1 $BACKUPROOT/
	echo 'done.'
	return $?
}

restore () {
	stopSRB
	if test -f $1; then
		tar -xpPf $1
		dropdb MCAT
		createdb MCAT
		psql MCAT < $SRBHOME/MCAT.dump
		rm $SRBHOME/MCAT.dump
		if [ $? -eq 0 ]; then
			startSRB
		fi
		return $?
	fi
		return 1
}

clean () {
	echo "Cleaning old local backups..."
        find $BACKUPROOT -mtime +$TIME_TO_KEEP | xargs rm -rf
        echo "done."
}

case "$1" in
	backup)
		backup srb-backup-$HOST-$NOW.tar
		;;
	restore)
		restore $2 srb-backup-$HOST-$NOW-before_restore.tar
		;;
	clean)
		clean
		;;
*)
	echo $"Usage: $0 {backup|restore <ARCHIVE>|clean}"
	exit 1
esac

exit $?

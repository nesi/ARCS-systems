#!/bin/bash
# msyql_backup.sh
# script to backup the mysql server
# $Id$
# $HeadURL$

MODE=$1
MYSQLUSER=backup
BINLOGPATH=/data/mysql/m3306
BINLOGNAME=mysqld-bin
ARCHIVEPATH=/data/mysql/backups/m3306
SOCKET=$BINLOGPATH/mysql.sock

copyBinlogs() {
    # copy binlogs to archive dir
    echo "Copying binlogs"
    pushd $BINLOGPATH
    for FILE in `cat $BINLOGPATH/$BINLOGNAME.index`
      do
      SFILE=(${FILE/*\//})
      if [ ! -f $ARCHIVEPATH/$SFILE.gz ]
	  then
	  echo "- binlog $SFILE"
	  cp -p $FILE $ARCHIVEPATH
	  gzip $ARCHIVEPATH/$SFILE
      fi
    done
    popd
}

saveBinlogs() {
   # move latest binlogs to savedir
    echo "Saving binlogs"
    SAVEDIR=`date +%Y%m%d`
    echo $SAVEDIR
    mkdir -p $ARCHIVEPATH/$SAVEDIR
    mv $ARCHIVEPATH/*.gz $ARCHIVEPATH/$SAVEDIR
}

# --- Main ---
case "$MODE" in

    'full')
    # Weekly backup
    # - copy all bin logs to backup directory
    # - clean path of backup directory
	echo "Weekly backup"
        date
	DATE=`date +%Y%m%d`
	if [ ! -d $ARCHIVEPATH/$DATE ]
	then
	    mkdir -p $ARCHIVEPATH/$DATE
	fi
	mysqldump -u $MYSQLUSER -S $SOCKET \
            --single-transaction --flush-logs --master-data=2 \
	    --all-databases | gzip > $ARCHIVEPATH/$DATE/full-$DATE.sql.gz
	STATUS=${PIPESTATUS[0]}
	if [ "$STATUS" -ne "0" ]; then
		echo mysqldump failed
		exit $STATUS
	fi
	copyBinlogs;
	saveBinlogs;
	;;

    'incremental')
    # Daily backup
    # - flush logs
    # - copy all bin logs to backup directory if not already done
	echo "Mysql daily backup"
        date
	mysqladmin -u $MYSQLUSER -S $SOCKET flush-logs
	STATUS=$?
	if [ $STATUS -ne 0 ]; then
		echo mysqladmin flush logs failed
		exit $STATUS
	fi
	copyBinlogs;
	;;
    
    *)
	echo "Usage: mysql_backup [full|incremental]"
	exit 1
	;;
    
esac
echo "Copy mysql dump to data fabric"
/opt/iRODS/iRODS/clients/icommands/bin/irsync -rvs $ARCHIVEPATH i:`hostname -s`.m3306
STATUS=$?
if [ $STATUS -ne 0 ]; then
	echo copy mysql dump to data fabric failed
	exit $STATUS
fi

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

#setRead() {
#    # change properties on binlog path
#    sudo /bin/chmod o+rx $BINLOGPATH
#    sudo /bin/chmod o+r $BINLOGPATH/*
#}
#
#resetRead() {
#    # restore properties on binlog path
#    sudo /bin/chmod o-r $BINLOGPATH/*
#    sudo /bin/chmod o-rx $BINLOGPATH
#}

copyBinlogs() {
    # copy binlogs to archive dir
    echo "Copying binlogs"
#    setRead;
    pushd $BINLOGPATH
    for FILE in `cat $BINLOGPATH/$BINLOGNAME.index`
      do
      SFILE=(${FILE/*\//})
      if [ ! -f $ARCHIVEPATH/$SFILE.gz ]
	  then
	  echo "- binlog $SFILE"
	  cp $FILE $ARCHIVEPATH
	  gzip $ARCHIVEPATH/$SFILE
      fi
    done
    popd
#    resetRead;
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
	DATE=`date +%Y%m%d`
	if [ ! -d $ARCHIVEPATH/$DATE ]
	then
	    mkdir -p $ARCHIVEPATH/$DATE
	fi
	mysqldump -u $MYSQLUSER -S $SOCKET \
            --single-transaction --flush-logs --master-data=2 \
	    --all-databases | gzip > $ARCHIVEPATH/$DATE/full-$DATE.sql.gz
	copyBinlogs;
	saveBinlogs;
	;;

    'incremental')
    # Daily backup
    # - flush logs
    # - copy all bin logs to backup directory if not already done
	echo "Mysql daily backup"
	mysqladmin -u $MYSQLUSER -S $SOCKET flush-logs
	copyBinlogs;
	;;
    
    *)
	echo "Usage: mysql_backup [full|incremental]"
	;;
    
esac

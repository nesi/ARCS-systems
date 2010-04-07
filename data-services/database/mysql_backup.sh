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
    rsync -av $BINLOGPATH/$BINLOGNAME.* $ARCHIVEPATH/
    echo "binlogs copied"
}

# --- Main ---
case "$MODE" in

    'full')
    # Weekly backup
    # - copy all bin logs to backup directory
    # - clean path of backup directory
        echo "mysql Weekly backup"
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
                echo error: mysqldump failed
                exit $STATUS
        fi
        copyBinlogs;
        cp -p $BINLOGPATH/$BINLOGNAME.index $ARCHIVEPATH/$DATE
        ;;

    'incremental')
    # Daily backup
    # - flush logs
    # - copy all bin logs to backup directory if not already done
        echo "mysql Daily backup"
        date
        mysqladmin -u $MYSQLUSER -S $SOCKET flush-logs
        STATUS=$?
        if [ $STATUS -ne 0 ]; then
                echo error: mysqladmin flush logs failed
                exit $STATUS
        else
                echo mysqladmin flush complete
        fi
        copyBinlogs;
        ;;
    
    *)
        echo "Usage: mysql_backup [full|incremental]"
        exit 1
        ;;
    
esac
echo "Copy mysql backup to data fabric"
IRSYNC=/opt/iCommands/iRODS/clients/icommands/bin/irsync
$IRSYNC -rs $ARCHIVEPATH i:`hostname -s`.m3306
STATUS=$?
if [ $STATUS -ne 0 ]; then
        echo warning: irsync mysql dump to data fabric failed
        exit $STATUS
fi

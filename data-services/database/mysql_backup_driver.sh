#!/bin/bash
# msyql_backup_driver.sh
# script to drive the backup the mysql server
# $Id$
# $HeadURL$

MODE=$1
TMPDIR=/tmp
fail_address=arcs-data@arcs.org.au
#success_address=florian.goessmann@arcs.org.au
success_address=pauline.mak@arcs.org.au,florian.goessmann@arcs.org.au

/usr/local/bin/mysql_backup.sh $MODE > $TMPDIR/mysql_backup.log 2>&1
STATUS=$?
if grep -qi error $TMPDIR/mysql_backup.log || test $STATUS -gt 0; then
 mail -s "ERROR! mysql backup failed on `/bin/hostname` exit $STATUS" $fail_address < $TMPDIR/mysql_backup.log
else
 mail -s "mysql backup success on `/bin/hostname`" $success_address < $TMPDIR/mysql_backup.log
fi
cat $TMPDIR/mysql_backup.log >> /var/log/mysql_backup.log
sleep 10 # might be needed for the mail to get sent
exit $?

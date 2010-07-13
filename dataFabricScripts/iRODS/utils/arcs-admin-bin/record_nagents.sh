#!/bin/sh
# record_nagents.sh  Prints the number of running irodsAgent processes
#                  Should be called at 5-minute intervals from cron.
#                  Gareth May 2010. Rev: 20100526
# $Id$
# $HeadURL$

# Destination function, Path, Usage ..
Destin() {
  echo /tmp/`basename $0`.`date +%a`
}
PATH=/usr/bin:/bin
if [ -n "$1" ]; then
  ( echo "Usage: `basename $0`"
    echo " Note: Today's results will appear in file: "`Destin`) >&2
  exit 2
fi 

# If filename has changed, clean it out
File=`Destin`
echo $File >~/.`basename $0.new`
cmp ~/.`basename $0.new` ~/.`basename $0` >/dev/null 2>&1 || >$File
mv -f ~/.`basename $0.new` ~/.`basename $0`

# Append the result and exit
( echo "`date` .. no. irodsAgent procs: `ps -U rods | grep -c irodsAgent`" ) >>$File
exit 0


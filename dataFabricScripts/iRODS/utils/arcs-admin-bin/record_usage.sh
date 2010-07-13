#!/bin/sh
# record_usage.sh  Prints VM and RSS usage for designated users.
#                  Should be called at 5-minute intervals from cron.
#                  Graham Jenkins <graham@vpac.org> April 2010. Rev: 20100419
# $Id$
# $HeadURL$

# Destination function, Path, Usage ..
Destin() {
  echo /tmp/`basename $0`.`date +%a`
}
PATH=/usr/bin:/bin
if [ -z "$1" ]; then
  ( echo "Usage: `basename $0` userlist"
    echo " E.g.: `basename $0` rods,davis,jetty"
    echo " Note: Today's results will appear in file: "`Destin`) >&2
  exit 2
fi 

# If filename has changed, clean it out
File=`Destin`
echo $File >~/.`basename $0.new`
cmp ~/.`basename $0.new` ~/.`basename $0` >/dev/null 2>&1 || >$File
mv -f ~/.`basename $0.new` ~/.`basename $0`

# Append the result and exit
( echo "`date` .. Jobs for user(s): $1"
  ps -U $1 -o vsz,rss,uname,pid,comm --sort -vsz 
  echo -- ) >>$File
exit 0


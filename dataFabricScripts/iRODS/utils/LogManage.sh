#!/bin/bash
# LogManage.sh  Manages Log Files for Davis and other applications.
#               Graham Jenkins <graham@vpac.org> Jan. 2011; Rev. 20110202

# Usage check
case "$3" in
  [1-9]|[1-9][0-9]|[1-9][0-9][0-9] ) NumGood="Y" ;;
esac
[ \( ! -d "$1" \) -o \( $# -ne 3 \) -o \( -z "$NumGood" \) ] &&
  ( echo "Usage: `basename $0` log-directory log-template max-days"
    echo " e.g.: `basename $0` /home/davis/logs request.log$ 90"
    echo "       `basename $0` /opt/jetty-6.1.18/logs ^threddsServlet.log 14"
    echo " Note: max-days must not exceed 999") >&2 && exit 2

# Keep the 3 newest uncompressed Log Files, compress the rest
for logFile in \
  `ls -1t "$1" | grep "$2" | grep -v "\.bz2$" | sed -n '4,$p' 2>/dev/null`; do
  logger -i -t `basename $0` "Compressing: $1/$logFile"
  nice bzip2 -9qf $1/$logFile
done

# Remove compressed Log Files older than max-days days
for logFile in \
   `find $1 -maxdepth 1 -type f -name "*.bz2" -mtime +$3 | sort`; do
  basename "$logFile" | sed -e 's/\.bz2$//' | grep -q "$2" || continue
  logger -i -t `basename $0` "Removing: $logFile"
  rm -f $logFile
done
 
exit 0

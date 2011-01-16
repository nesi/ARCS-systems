#!/bin/sh
# gloPut7C.sh  Copies files in a designated directory to a remote server.
#              Requires threaded globus-url-copy; uses gsiftp with certificates.
#              Graham.Jenkins@arcs.org.au  Dec. 2010. Rev: 20110117

# Environment; adjust as appropriate
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage
Match="."
while getopts rm: Option; do
  case $Option in
    r) Order="-r";;
    m) Match=$OPTARG;;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 2 \) ] &&
  ( echo "  Usage: `basename $0` directory destination"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "gsiftp://hn3.its.monash.edu.au/mnt/arcs/"
    echo "Options: -m String .. send only files whose names contain 'String'"
    echo "         -r        .. reverse order"                   ) >&2 && exit 2

# Transmit all files in the directory, maintaining a piplein of several jobs
for File in `find -L $1 -maxdepth 1 -type f | grep $Match | sort $Order`; do
  [ ! -r "$File" ] && continue
  [ -z "$Flag" ] && echo "`date '+%a %T'` .. Starting first file .." && Flag=Y
  if globus-url-copy -q -cd -fast file:///$File $2/ 2>/dev/null; then
    echo "`date '+%a %T'` .. `wc -c $File` .. OK"
  else
    echo "`date '+%a %T'` .. `wc -c $File` .. Failed!"; sleep 5
  fi &
  until [ `jobs | wc -l` -lt 8 ] ; do
    sleep 1
  done
done
wait

echo "No more files to be copied!"

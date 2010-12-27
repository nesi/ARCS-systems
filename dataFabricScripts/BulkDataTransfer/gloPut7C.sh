#!/bin/sh
# gloPut7C.sh  Copies files in a designated directory to a remote server.
#              Requires threaded globus-url-copy; uses gsiftp with certificates.
#              Graham.Jenkins@arcs.org.au  Dec. 2010. Rev: 20101228

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
    echo "Optione: -m String .. send only files whose names contain 'String'"
    echo "         -r        .. reverse order"                   ) >&2 && exit 2

for File in `find $1 -maxdepth 1 -type f | grep $Match | sort $Order`; do
  [ \( ! -f "$File" \) -o \( ! -r "$File" \) ] && continue
  echo -n "`date '+%a %T'` .. `wc -c $File` .. " 
  if globus-url-copy -q -cd -fast file:///$File $2/ 2>/dev/null; then
    echo OK
  else
    echo Failed; sleep 5
  fi
done

echo "No more files to be copied!"

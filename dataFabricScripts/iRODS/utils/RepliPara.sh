#!/bin/sh
# RepliPara  Performs parallel replication of files not currently replicated.
#            Graham Jenkins <graham@vpac.org> Nov. 2009. Rev: 20091130

# Path, options, usage
Count=8                 # Default; adjust as appropriate
Resou=ARCS-REPLISET     # Ditto
PATH=$PATH:/usr/local/bin
while getopts Qp:R:h Option; do
  case $Option in
    Q   ) Quick="-Q";;
    p   ) Count=$OPTARG;;
    R   ) Resou=$OPTARG;;
    h|\?) Bad=Y;;
  esac
done
shift `expr $OPTIND - 1`
if [ \( -n "$Bad" \) -o \( -z "$1" \) ] ; then
  echo "Usage: `basename $0` [-Q] [-p count] [-R resource] Coll1 [Coll2 ..]">&2
  echo " e.g.: `basename $0` -p $Count -R $Resou /ARCS/home /ARCS/projects" >&2
  exit 2
fi

# Create flag-file, set trap for signal to remove it, swallow other signals
FlagFile=`mktemp`
trap ""                                            0 1 2 3 4 15
trap "rm -f $FlagFile; echo Break detected .. wait" USR1 

# Process each nominated collection
for Collection in "$@" ; do
  echo "Replicating: $Collection   with: $Count parallel replications"
  echo "to resource: $Resou .. For graceful termination, do:  kill -USR1 $$"
  RepliCheck.sh "$Collection" |
  while read Line ; do
    [ ! -f $FlagFile ] && wait && exit 0
    eval irepl -MBTv $Quick -R $Resou "$Line" &
    while  [ `jobs | wc -l` -gt $Count ] ; do
      sleep 1
    done
  done
  echo
done
wait

# All done, remove flag-file and exit
echo
rm -f $FlagFile
exit 0

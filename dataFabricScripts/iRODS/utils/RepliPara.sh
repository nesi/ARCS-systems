#!/bin/sh
# RepliPara  Performs parallel replication of files not currently replicated.
#            Graham Jenkins <graham@vpac.org> Nov. 2009. Rev: 20091208

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
  Zon="`ienv | awk -F= '/irodsZone/ {print \$NF}'`"; [ -z "$Zon" ] && Zon=ARCS
  echo "Usage: `basename $0` [-Q] [-p count] [-R resource] Coll1 [Coll2 ..]">&2
  echo " e.g.: `basename $0` -p $Count -R $Resou /$Zon/home /$Zon/projects" >&2
  exit 2
fi

# Set trap for graceful termination
FlagFile=`mktemp`
trap "Count=-1; echo Break detected .. wait" 1 2 3 15

# Process each nominated collection
for Collection in "$@" ; do
  echo "Replicating: $Collection   with: $Count parallel replications"
  echo "to resource: $Resou .. "
  RepliCheck.sh "$Collection" |
  while read Line ; do
    [ $Count -lt 0 ] && break 2
    echo "Replicating: $Line"
    eval irepl -MBT $Quick -R $Resou "$Line" &
    while [ `jobs | wc -l` -ge $Count ] ; do
      sleep 1
    done
  done
  echo
done
wait

# All done, exit
echo
exit 0

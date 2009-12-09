#!/bin/sh
# RepliBatch Performs batch replication of files not currently replicated.
#            Graham Jenkins <graham@vpac.org> Nov. 2009. Rev: 20091210

# Path, options, usage
Count=16                # Default; adjust as appropriate
Resou=ARCS-REPLISET     # Ditto
PATH=$PATH:/usr/local/bin
while getopts Qb:R:h Option; do
  case $Option in
    Q   ) Quick="-Q";;
    b   ) Count=$OPTARG;;
    R   ) Resou=$OPTARG;;
    h|\?) Bad=Y;;
  esac
done
shift `expr $OPTIND - 1`
if [ \( -n "$Bad" \) -o \( -z "$1" \) ] ; then
  Zon="`ienv | awk -F= '/irodsZone/ {print \$NF}'`"; [ -z "$Zon" ] && Zon=ARCS
  echo "Usage: `basename $0` [-Q] [-b count] [-R resource] Coll1 [Coll2 ..]">&2
  echo " e.g.: `basename $0` -b $Count -R $Resou /$Zon/home /$Zon/projects" >&2
  exit 2
fi

# Check 'Count' value
case "$Count" in
  [1-9]|[0-3][0-9] ) ;;
  *) Count=16; echo "Adjusting: excessive or in-appropriate value for 'count'";;
esac

# Generate a list of objects to be replicated, insert empty line to mark end
echo "Replicating: $@"
echo "in batches of: $Count  to resource: $Resou"
echo
J=0
( for Collection in "$@" ; do
    RepliCheck.sh "$Collection"
  done
  echo ) |

# Process the list records in batches, flush when end marker seen
while read Line ; do
  [ $J -lt 1 ] && [ -n "$Line" ] && date
  J=`expr 1 + $J`
  [ -n "$Line" ] && echo "$Line" && String="$String $Line" || J=999
  if [ $J -ge $Count ]; then
    [ -n "$String" ] && echo && eval irepl -MBT $Quick -R $Resou "$String"
    J=0 ; String=""
  fi
done

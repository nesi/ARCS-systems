#!/bin/ksh
# repliPrune.sh Ascertains which objects have more than 2 clean replicas, and
#               removes replicas so that there are only 2.  Excess replicas are
#               retained where one replica is on an 's3' resource.
#               Graham Jenkins <graham@vpac.org> July 2010. Rev: 20100907

# Path, usage check
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin
while getopts nh Option; do
  case $Option in
    n   ) ListOnly=Y;;
    h|\?) Bad=Y;;
  esac
done
shift `expr $OPTIND - 1`

if [ \( -n "$Bad" \) -o \( -z "$1" \) ] ; then
  ( echo "  Usage: `basename $0` [-n] Collection [Collection2 ..]"
    echo "   e.g.: `basename $0` /ARCS/home /ARCS/projects/EMXRAY"
    echo
    echo "Options: -n  No action; just show what would be done"
    echo "         -h  Show this message"
  ) >&2 && exit 2
fi

# Generate an array of objects which have a replica on an 's3' resource
typeset -A s3obj
for Collection in "$@" ; do
  iquest --no-page "%s/%s" "select COLL_NAME,DATA_NAME
                             where RESC_TYPE_NAME = 's3'
                               and COLL_NAME like '${Collection}/%'" 2>/dev/null |
                                                              sed 's/\$/\\\\$/g' |
  while read s3Line; do
    s3obj["\"$s3Line\""]=Y
  done
done

# Generate clean-replica count for each object in designated collection(s)
for Collection in "$@" ; do
  iquest --no-page "%s%s/%s" "select count(DATA_REPL_NUM),COLL_NAME,DATA_NAME
    where COLL_NAME like '${Collection}/%' 
    and DATA_REPL_STATUS = '1'" 2>/dev/null 
done | sed 's/\$/\\\\$/g' |

# Process each object
while read Line; do

  # Skip objects which have less than 3 clean replicas 
  Count="`echo \"$Line\" | awk '{slashpos=index(\$0,"/")
                                       print substr(\$0,1,slashpos-1)}'`"
  [ "$Count" -lt 3 ]             && continue
  Object="`echo \"$Line\"| awk '{slashpos=index(\$0,"/")
                                       print substr(\$0,slashpos    )}'`"
  # Skip objects which have a replica on an 's3' resource
  [ -n ${s3obj["\"$Object\""]} ] && continue 

  # Remove replicas on the same resource
  for Resource in  \
      `eval ils -l "\"$Object\""|awk '/ & / {print $3}'|sort|uniq -d|head -1`;do
    for Replica in \
        `eval ils -l "$Line" |awk '{if($3==r) print $2}' r=$Resource`; do
      echo SAME-RESOURCE itrim -M -n ${Replica} "\"$Object\""
      [ -z "$ListOnly" ] && eval itrim -M -n ${Replica} "\"$Object\""
    done
  done

  # Remove other excessive replicas
  n=0
  for Replica in `eval ils -l "\"$Object\"" | awk '/ & / {print $2}'`; do
    n=`expr 1 + $n`
    repNum[$n]=$Replica
  done
  for k in `seq 3 $n`; do
    echo EXCESSIVE itrim -M -n ${repNum[k]} "\"$Object\""
    [ -z "$ListOnly" ] && eval itrim -M -n ${repNum[k]} "\"$Object\""
  done

done

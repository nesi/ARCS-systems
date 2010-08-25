#!/bin/ksh
# repliPrune.sh Ascertains which objects have more than 2 clean replicas, and
#               removes replicas so that there are only 2.  Excess replicas are
#               retained where one replica is on an 's3' resource.
#               Graham Jenkins <graham@vpac.org> July 2010. Rev: 20100826

# Path, usage check
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin
while getopts nd Option; do
  case $Option in
    n   ) ListOnly=Y;;
    d   ) DirtyOnly=Y;;
    h|\?) Bad=Y;;
  esac
done
shift `expr $OPTIND - 1`

if [ \( -n "$Bad" \) -o \( -z "$1" \) ] ; then
  ( echo "  Usage: `basename $0` [-n] [-d] Collection [Collection2 ..]"
    echo "   e.g.: `basename $0` /ARCS/home /ARCS/projects/EMXRAY"
    echo
    echo "Options: -n  No action; just show what would be done"
    echo "         -d  \"Dirty\" and \"Same Resource\" processing only" 
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

# List the files with more than 2 replicas
for Collection in "$@" ; do
  iquest --no-page "%s %s/%s" "select count(DATA_REPL_NUM),COLL_NAME,DATA_NAME
      where COLL_NAME like '${Collection}/%'" 2>/dev/null |
      awk '{ if ($1 > 2) {
              j=index($0," ")
              if(j>0) print "\""substr($0,j+1)"\""
            } }'
done | sed 's/\$/\\\\$/g' |

# Process each record in the list
while read Line; do

  # Update dirty replicas
  for Replica in `eval ils -l "$Line" | awk '{if($6 != "&") print $2}'`; do
    echo "DIRTY(#"$Replica")" irepl -MUT "$Line"
    [ -z "$ListOnly" ] && eval irepl -MUT "$Line" 
  done 

  # Remove replicas on the same resource
  for Resource in  \
      `eval ils -l "$Line"|awk '/ & / {print $3}'|sort|uniq -d|head -1`; do
    for Replica in \
        `eval ils -l "$Line" |awk '{if($3==r) print $2}' r=$Resource`; do
      echo SAME-RESOURCE itrim -M -n ${Replica} "$Line"
      [ -z "$ListOnly" ] && eval itrim -M -n ${Replica} "$Line"
    done
  done

  # Remove other excessive replicas
  [ -n "$DirtyOnly" ] && continue
  n=0
  for Replica in `eval ils -l "$Line" | awk '/ & / {print $2}'`; do
    n=`expr 1 + $n`
    repNum[$n]=$Replica
  done
  [ -n ${s3obj["$Line"]} ] && echo "SKIPPING (s3)" $Line && continue
  for k in `seq 3 $n`; do
    echo EXCESSIVE itrim -M -n ${repNum[k]} "$Line"
    [ -z "$ListOnly" ] && eval itrim -M -n ${repNum[k]} "$Line"
  done

done

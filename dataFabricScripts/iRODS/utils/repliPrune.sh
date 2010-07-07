#!/bin/ksh
# repliPrune.sh Ascertains which files have more than 2 clean replicas, and
#               removes replicas so that there are only 2.
#               Graham Jenkins <graham@vpac.org> July 2010. Rev: 20100707

# Path, usage check
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS
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

# List the files with more than 2 replicas
for Collection in "$@" ; do
  ( yes | iquest "%s %s/%s" "select count(DATA_REPL_NUM),COLL_NAME,DATA_NAME
      where COLL_NAME like '${Collection}/%'" ) 2>/dev/null |
      awk '{if ($0 ~ /^Continue?/) $0=substr($0,16)
            if ($1 > 2) {
              j=index($0," ")
              if(j>0) print "\""substr($0,j+1)"\""
            } }'
done |

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
  for k in `seq 3 $n`; do
    echo EXCESSIVE itrim -M -n ${repNum[k]} "$Line"
    [ -z "$ListOnly" ] && eval itrim -M -n ${repNum[k]} "$Line"
  done

done

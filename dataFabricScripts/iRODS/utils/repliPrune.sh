#!/bin/ksh
# repliPrune.sh  Ascertains which files have more than 2 clean replicas, and
#                removes replicas so that there are only 2.
#                Graham Jenkins <graham@vpac.org> May 2010. Rev: 20100601

# Path, usage check
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin
String="removing"
[ "$1" = "-n" ] && ListOnly=Y && shift && String="would remove"
[ -z "$1" ] &&
  ( echo "Usage: `basename $0` [-n] Collection [Collection2 ..]"
    echo " e.g.: `basename $0` /ARCS/home /ARCS/projects/IMOS"
    echo " Note: Use option '-n' to show what would be done"
  ) >&2 && exit 2

# List the files with more than 2 replicas
ils -lr "$@" 2>/dev/null | awk '{
  if ($1~"^/") {    # Extract collection names from records starting in "/".
    Dir=substr($0,1,length-1)
  }
  else {            # Extract filenames from non-collection records,
    if ($1!="C-") { # and skip those whose size is non-positive ..
      amperpos=index($0," & ")
      if ( (amperpos>0) &&  ($4>0 )) {
                    # If a filename is the same as the last, increment count
                    # And if the count exceeds 1, print the filename
        curr="\""Dir"/"substr($0,amperpos+3)"\""
        if ( curr  == prev ) { count++    } else { count=0; prev=curr }
        if ( count == 2    ) { print curr }
      }
    }
  }
}' |

# For each file, get the set of replica numbers, the remove all except the
# first two replicas
while read Line; do
  n=0
  echo
  echo "$Line"
  eval ils -l "$Line"
  if [ -n "`eval ils -l \"$Line\"|awk '/ & / {print $3}'|sort| uniq -d`" ]; then
    echo "== ^^ REPLICAS ON SAME RESOURCE, PROCESSING SKIPPED! ^^ =="
  else
    for Replica in `eval ils -l "$Line" | awk '/ & / {print $2}'`; do
      n=`expr 1 + $n`
      repNum[$n]=$Replica
    done
    for k in `seq 3 $n`; do
      echo " .. $String replica number: ${repNum[k]}"
      [ -z "$ListOnly" ] && eval itrim -M -n ${repNum[k]} "$Line" 
    done
  fi
done

# All done
echo

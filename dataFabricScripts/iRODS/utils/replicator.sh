#!/bin/ksh
# replicator.sh  Replicator script intended for invovation (as the iRODS user)
#                from /etc/init.d/replicator
#                Graham Jenkins <graham@vpac.org> Jan. 2010. Rev: 20100824

# Batch size, path, usage check
BATCH=16
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin:/usr/local/bin
[ "$1" = "-n" ] && ListOnly=Y && shift
[ -z "$2" ] &&
  ( echo "Usage: `basename $0` [-n] Resource Collection [Collection2 ..]"
    echo " e.g.: `basename $0` ARCS-REPLISET /ARCS/home /ARCS/projects/IMOS"
    echo " Note: Use option '-n' to show what would be done, then exit"
  ) >&2 && exit 2

# Extract resource-name, loop forever
Resource="$1"; shift
while : ; do

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

  # List all files with full collection path, print those that appear only once
  logger -i "Replicating to $Resource .. $@"
  J=0
  ils -lr "$@" 2>/dev/null | awk '{
    if ($1~"^/") {    # Extract collection names from records starting in "/".
      Dir=substr($0,1,length-1)
    }
    else {            # Extract file names from non-collection records,
      if ($1!="C-") { # and skip those whose size is non-positive ..
        amperpos=index($0," & ")
        if(amperpos>0) if($4>0) print "\""Dir"/"substr($0,amperpos+3)"\""
      }
    }
  }' | uniq -u | sed 's/\$/\\\\$/g' | shuf |
  
  # Feed the randomly-ordered list records into a parallel-job launch-pipe
  while read Line ; do
    [ -n ${s3obj["$Line"]} ]            && continue
    [ -n "$ListOnly"  ] && echo "$Line" && continue
    eval irepl -MBT -R $Resource "$Line" &
    while [ `jobs | wc -l` -ge $BATCH ] ; do
      sleep 1
    done
  done

  # 18-hour pause
  logger -i "Replication pass completed!"
  echo "Replication pass completed!" >&2
  [ -n "$ListOnly" ] && exit 0
  sleep 64800

done

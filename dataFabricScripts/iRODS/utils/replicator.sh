#!/bin/sh
# replicator.sh  Replicator script intended for invovation (as the iRODS user)
#                from /etc/init.d/replicator
#                Graham Jenkins <graham@vpac.org> Jan. 2010. Rev: 20100312

# Batch size, path, usage check
BATCH=16
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin
[ "$1" = "-n" ] && ListOnly=Y && shift
[ -z "$2" ] &&
  ( echo "Usage: `basename $0` [-n] Resource Collection [Collection2 ..]"
    echo " e.g.: `basename $0` ARCS-REPLISET /ARCS/home /ARCS/projects/IMOS"
    echo " Note: Use option '-n' to show what would be done, then exit"
  ) >&2 && exit 2

# Extract resource-name, loop forever
Resource="$1"; shift
while : ; do
  # List all files with full collection path, print those that appear only once
  logger -i "Replicating to $Resource .. $@"
  J=0
  ( ils -lr "$@" | awk '{
      if ($1~"^/") {    # Extract collection names from records starting in "/".
        Dir=substr($0,1,length-1)
      }
      else {
        if ($1!="C-") { # Extract file names from non-collection records
          amperpos=index($0," & ")
          if(amperpos>0) print "\""Dir"/"substr($0,amperpos+3)"\""
        }
      }
    }' | uniq -u | sed 's/\$/\\\\$/g'
  echo                  # Append empty line to mark end of list
  ) | 
  
  # Process the list records in batches, flush when end marker seen
  while read Line ; do
    if [ -n "$Line" ] ; then
      # Skip files whose size is non-positive
      FileSize=`eval ils -l "$Line" | awk '{print $4; exit}'`
      [ `expr $FileSize + 0` -le 0 ]      && continue
      [ -n "$ListOnly"  ] && echo "$Line" && continue
    fi
    J=`expr 1 + $J`
    [ -n "$Line" ] && String="$String $Line" || J=999
    if [ $J -ge $BATCH ] ; then
      [ -n "$String" ] && eval irepl -MBT -R $Resource "$String" 
      J=0 ; String=""
    fi
  done

  # Sixty-minute pause
  [ -n "$ListOnly" ] && exit 0
  logger -i "Replication pass completed!"
  echo "Replication pass completed!" >&2
  sleep 3600

done

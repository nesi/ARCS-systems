#!/bin/ksh
# replicator.sh  Replicator script intended for invocation (as the iRODS user)
#                from /etc/init.d/replicator
#                Graham Jenkins <graham@vpac.org> Jan. 2010. Rev: 20100901

# Batch size, path, usage check
BATCH=16
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin:/usr/local/bin
Zone=`iquest "%s" "select ZONE_NAME" 2>/dev/null`
[ "$1" = "-n" ] && ListOnly=Y && shift
[ -z "$2" ] &&
  ( echo "Usage: `basename $0` [-n] Resource Collection [Collection2 ..]"
    echo " e.g.: `basename $0` ARCS-REPLISET /$Zone/home /$Zone/projects/IMOS"
    echo " Note: Use option '-n' to show what would be done, then exit"
  ) >&2 && exit 2

# Extract resource-name, loop forever
Resource="$1"; shift
while : ; do

  # Clean dirty replicas
  logger -i -t `basename $0` "Cleaning Dirty Replicas"
  iquest --no-page "%s/%s" "select COLL_NAME,DATA_NAME
    where COLL_NAME not like '/ARCS/trash/%'
    and   DATA_REPL_STATUS <> '1'
    and   DATA_SIZE        <> '0'" 2>/dev/null | sed 's/\$/\\\\$/g' |
  while read Object; do
    eval ils -l "\"$Object\"" | grep " & " >/dev/null 2>&1 || continue
    [ -n "$ListOnly" ] && echo DIRTY: irepl -MUT "\"$Object\"" && continue
    DirtyTotal=`eval ils -l "\"$Object\"" | grep -v " & " | wc -l`
    for Count in `seq 1 $DirtyTotal`; do
      eval irepl -MUT "\"$Object\""
    done
  done

  # Process objects which have a clean replica on an 's3' resource
  typeset -A s3obj
  for s3Resc in `iquest --no-page "%s" "select RESC_NAME
    where RESC_TYPE_NAME = 's3'" 2>/dev/null`; do
    logger -i -t `basename $0` "Processing objects on 's3' resource: $s3Resc"
    iquest --no-page "%s%s/%s" "select DATA_REPL_NUM,COLL_NAME,DATA_NAME
      where  RESC_NAME = '$s3Resc'
      and   DATA_SIZE  <> '0'" 2>/dev/null | sed 's/\$/\\\\$/g'  |
    while read Line; do
      GoodRep="`echo \"$Line\" | awk '{slashpos=index(\$0,"/")
                                       print substr(\$0,1,slashpos-1)}'`"
      Object="`echo \"$Line\"  | awk '{slashpos=index(\$0,"/")
                                       print substr(\$0,slashpos    )}'`"
      s3obj["\"$Object\""]=Y
      [ -z "$GoodRep" ] && continue
      for Replica in \
        `eval ils -l "\"$Object\""|awk '{if(\$2!=r) print \$2}' r=$GoodRep`; do
         if [ -n "$ListOnly" ] ; then
           echo TRIM: itrim -M -N 1 -n $Replica "\"$Object\""
         else
           eval       itrim -M -N 1 -n $Replica "\"$Object\"" 
         fi
      done
    done
  done

  # List all files with full collection path, print those that appear only once
  logger -i -t `basename $0` "Replicating to $Resource .. $@"
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
    [ -n "$ListOnly"  ] &&echo REPLIC: irepl -MBT -R $Resource "$Line"&&continue
    eval irepl -MBT -R $Resource "$Line" &
    while [ `jobs | wc -l` -ge $BATCH ] ; do
      sleep 1
    done
  done
  wait

  # 1-hour pause
  logger -i -t `basename $0` "Replication pass completed!"
  echo "Replication pass completed!" >&2
  [ -n "$ListOnly" ] && exit 0
  sleep 3600

done

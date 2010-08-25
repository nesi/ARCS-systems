#!/bin/ksh
# repliS3.sh    Manages replicas for file on Amazon S3 or similar resource.
#               Graham Jenkins <graham@vpac.org> August 2010. Rev: 20100826

# Path, options, user validation
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin
while getopts na Option; do
  case $Option in
    n   ) ListOnly=Y;;
    h|\?) Bad=Y;;
  esac
done
shift `expr $OPTIND - 1`

if [ \( -n "$Bad" \) -o \( -z "$1" \) ] ; then
  ( echo "  Usage: `basename $0` [-n] Resource [Resource2 ..]"
    echo "   e.g.: `basename $0` s3Resc_us"
    echo
    echo "Options: -n  No action; just show what would be done"
    echo "         -h  Shows this help message"
  ) >&2 && exit 2
fi

# Check objects on each 's3' resource in the parameter list
logger -i "Processing objects with replicas on S3 resource(s): $@"
for Resource in "$@" ; do

  if [ "`iquest --no-page \"%s\" \"select RESC_TYPE_NAME \
              where  RESC_NAME = '$Resource'\" 2>/dev/null`" != "s3" ]; then
    echo "=== $Resource ..  type is not  's3' .. Skipping!"
    continue
  fi

  echo "=== Checking objects on resource: $Resource"
  # Clean dirty replicas
  iquest --no-page "%s/%s" "select COLL_NAME,DATA_NAME
                       where  RESC_NAME = '$Resource'
                       and DATA_REPL_STATUS <> '1'" 2>/dev/null |
                                             sed 's/\$/\\\\$/g' |
  while read Object; do
    echo DIRTY irepl -MUT "\"$Object\""
    [ -z "$ListOnly" ] && eval irepl -MUT "\"$Object\""
  done

  # Remove non-s3 replicas 
  iquest --no-page "%s%s/%s" "select DATA_REPL_NUM,COLL_NAME,DATA_NAME
                       where  RESC_NAME = '$Resource'> 2" 2>/dev/null |
                                                   sed 's/\$/\\\\$/g' |
  while read Line; do
    GoodRep="`echo \"$Line\" | awk '{slashpos=index($0,"/")
                                     print substr($0,1,slashpos-1)}'`"
    Object="`echo \"$Line\"  | awk '{slashpos=index($0,"/")
                                     print substr($0,slashpos    )}'`"   
    for Replica in \
      `eval ils -l "\"$Object\""|awk '{if($2!=r) print $2}' r=$GoodRep`; do
       echo ACTION: itrim -M -N 1 -n $Replica "\"$Object\""
       [ -z "$ListOnly" ] && eval itrim -M -N 1 -n $Replica "\"$Object\""
    done
  done

done

# All done, exit
logger -i "Processing of objects with replicas on S3 resources completed!"
exit 0

#!/bin/sh
# s3Checker.sh  Checks that objects in a user's 'Archive_S3' collection are
#               actually stored on an 's3' resource.
#               Graham Jenkins <graham@vpac.org> Aug. 2010. Rev: 20101111

# Path, usage check
[ -z "$IRODS_HOME" ] && IRODS_HOME=/opt/iRODS/iRODS
PATH=/bin:/usr/bin:$IRODS_HOME/clients/icommands/bin:/usr/local/bin
[ "$1" = "-n" ] && ListOnly=Y && shift
[ $# -ne 1 ] &&
  ( Zone=`iquest "%s" "select ZONE_NAME" 2>/dev/null | head -1`
    echo "Usage: `basename $0` [-n] Zone" 
    echo " e.g.: `basename $0` $Zone"
    echo " Note: Use option '-n' to show what would be done, then exit"
  ) >&2 && exit 2

# Get the names of the zone and first 's3' resource
Zone=$1
Resource=`iquest --no-page "%s" "select DATA_RESC_NAME 
  where RESC_TYPE_NAME = 's3'" 2>/dev/null |head -1`
[ -z "$Resource" ] && echo "No 's3' resource found!" && exit 1
logger -i -t `basename $0` "Starting. First 's3' resource is: $Resource"

( # Files in 'Archive_S3' collections
  iquest --no-page "%s/%s" "select COLL_NAME,DATA_NAME
    where COLL_NAME like '/$Zone/home/%/Archive_S3%'"
  # Files in 'Archive_S3' collections which have a replica on an s3 resource
  iquest --no-page "%s/%s" "select COLL_NAME,DATA_NAME
    where COLL_NAME like '/$Zone/home/%/Archive_S3%'
    and RESC_TYPE_NAME = 's3'"
) 2>/dev/null | sort | uniq -u | sed 's/\$/\\\\$/g' |

# Files which appear on only one of above lists need to be replicated 
while read Line ; do
  [ -n "$ListOnly" ] && echo ACTION: irepl -MBTR $Resource \"$Line\" && continue
  eval irepl -MBTR $Resource \"$Line\" >/dev/null 2>&1
done

# All done
logger -i -t `basename $0` "Ending."
exit 0

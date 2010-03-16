#!/bin/sh
# updateIrodsMapfile.sh  Updates the iRODS mapfile used by Griffin on "slave"
#                        servers; required for versions of iRODS below 2.3.
#                        Should be called at 30-min intervals by 'rods' cron.
#                        Graham Jenkins <graham@vpac.org> Rev: 20100317

# Usage, Temporary-file, trap
if   [ ! -w "$1" ] ; then
  ( echo "Usage: `basename $0` mapfile"
    echo " e.g.: `basename $0` /opt/griffin/irods-mapfile"
    echo " Note: Designated file must exist and be writeable!" ) >&2; exit 2
elif   ! TempFile=`mktemp` ; then
  logger -t `basename $0` "Failed to make temp-file!";                exit 1
fi
trap "rm -f $TempFile; exit 0" 0 1 2 3 4 15

# Generate the list
if ! `iquest "\"%s\" %s@%s" \
           "select USER_DN,USER_NAME,USER_ZONE where USER_DN like '/%'" \
              >$TempFile 2>/dev/null` ; then
  logger -t `basename $0` "iquest command failed!";                   exit 1
fi

# Update the file if necessary
if ! `cmp -s $TempFile $1`; then
  cp $TempFile $1 && logger -t `basename $0` "Updated: $1" &&         exit 0
  logger -t `basename $0` "Update failed!";                           exit 1
else
  exit 0
fi

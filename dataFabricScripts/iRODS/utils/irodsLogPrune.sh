#!/bin/bash
# irodsLogPrune.sh  Removes stale iRODS server log files.
#                   Graham Jenkins <graham@vpac.org> Jan. 2009; Rev. 201110106

# Usage check
[ ! -d "$1" ] &&
  ( echo "Usage: `basename $0` \$IRODS_HOME"
    echo " e.g.: `basename $0` /opt/iRODS/iRODS" ) >&2  && exit 2

# Keep the 4 newest rodLog, reLog files and rodsMonPerfLog files
( ls -1t        $1/server/log/rodsLog.[0-9][0-9][0-9][0-9].[0-9]* |sed -n '5,$p'
  ls -1t          $1/server/log/reLog.[0-9][0-9][0-9][0-9].[0-9]* |sed -n '5,$p'
  ls -1t $1/server/log/rodsMonPerfLog.[0-9][0-9][0-9][0-9].[0-9]* |sed -n '5,$p'
) 2>/dev/null |
while read logFile ; do
  logger -i -t `basename $0` "Removing: $logFile"
  rm -f $logFile
done
exit 0

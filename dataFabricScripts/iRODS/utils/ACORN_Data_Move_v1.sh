#!/bin/sh

icommandsDir="/opt/iRODS/iRODS/clients/icommands/bin"
today=`date '+%Y-%m-%d'`
curTime=`date '+%Y-%m-%d-%H-%M-%S'`
echo $curTime 

$icommandsDir/icp -rf /ARCS/projects/IMOS/staging/ACORN/range-time-series /ARCS/projects/IMOS/archive/ACORN
# $icommandsDir/icp -rf /ARCS/projects/IMOS/staging/ACORN/calibration-time-series /ARCS/projects/IMOS/archive/ACORN
echo "complete copying to archive" 
$icommandsDir/icp -rf /ARCS/projects/IMOS/staging/ACORN/radial /ARCS/projects/IMOS/opendap/ACORN
echo "complete copying to radial" 
$icommandsDir/icp -rf /ARCS/projects/IMOS/staging/ACORN/sea-state /ARCS/projects/IMOS/opendap/ACORN
echo "complete copying to sea-state" 

find /data/Vault/ARCS/projects/IMOS/opendap/ACORN/radial  -type d ! \( -perm -g=x \) -exec chmod -R g+xr {} \;
find /data/Vault/ARCS/projects/IMOS/opendap/ACORN/radial  -type f ! \( -perm -g=r \) -exec chmod g+r {} \;  -exec chgrp jetty {} \;

for irodsFileName in `find /data/Vault/ARCS/projects/IMOS/staging/ACORN -daystart -type f \( -mtime 0 -or -mtime 1 \)|cut -c12-`
do
   fileCopy=`echo $irodsFileName|sed 's/staging/opendap/g'`
   if [ -n "`ls /data/Vault$fileCopy 2>/dev/null`" ]; then
      echo "deleted file:" $irodsFileName `stat -c %y "/data/Vault"$irodsFileName` 
      $icommandsDir/irm -f $irodsFileName 
   fi  
done
echo "complete deletion" 




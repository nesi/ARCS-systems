#!/bin/sh

logDir="$IRODS_HOME/server/log"
today=`date '+%Y-%m-%d'`
curTime=`date '+%Y-%m-%d-%H-%M-%S'`
echo $curTime >> "$logDir/ACORN-Moving-Data"

icp -rf -R arcs-df.qcif.edu.au /ARCS/projects/IMOS/staging/ACORN/range-time-series /ARCS/projects/IMOS/archive/ACORN
# icp -rf -R arcs-df.qcif.edu.au /ARCS/projects/IMOS/staging/ACORN/calibration-time-series /ARCS/projects/IMOS/archive/ACORN
echo "complete copying to archive" >> "$logDir/ACORN-Moving-Data"
icp -rf -R arcs-df.qcif.edu.au /ARCS/projects/IMOS/staging/ACORN/radial /ARCS/projects/IMOS/opendap/ACORN
echo "complete copying to radial" >> "$logDir/ACORN-Moving-Data"
icp -rf -R arcs-df.qcif.edu.au /ARCS/projects/IMOS/staging/ACORN/sea-state /ARCS/projects/IMOS/opendap/ACORN
echo "complete copying to sea-state" >> "$logDir/ACORN-Moving-Data"

for irodsCollLeafNode in `find /data/Vault/ARCS/projects/IMOS/staging/ACORN -daystart -type d -mtime +1| sort | awk '$0 !~ last {print last} {last=$0} END {print last}'`
do
   irm -rf $irodsCollLeafNode   
done
echo "complete deletion" >> "$logDir/ACORN-Moving-Data"



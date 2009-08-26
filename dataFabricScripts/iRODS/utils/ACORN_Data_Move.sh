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

for collName in `yes|iquest "SELECT COLL_NAME WHERE COLL_NAME like '/ARCS/projects/IMOS/staging/ACORN%'" |grep COLL_NAME |cut -d' ' -f3`
do
      for collID in `yes|iquest "select COLL_ID where COLL_NAME like '$collName'" |grep COLL_ID |cut -d' ' -f3`
      do
          icd $collName
          for item in `psql ICAT -A -t -c "select data_name, modify_ts from r_data_main where coll_id = '$collID'"`
          do 
             fileName=`echo $item|cut -d'|' -f1`
             modifyTime=`echo $item|cut -d'|' -f2`
             modifyDate=`iadmin ctime $modifyTime|cut -d':' -f2|cut -d'.' -f1`
             if [ "$modifyDate" != "$today" ]; then 
                  irm -f $fileName
             else
                  dirName=`echo $collName|sed 's/staging/archive/g'`
                  fileCopy=`ils $dirName/$fileName 2>/dev/null`
                  if [ -n "$fileCopy" ]; then
                        irm -f $dirName/$fileName
                  fi
                  dirName=`echo $collName|sed 's/staging/opendap/g'`
                  fileCopy=`ils $dirName/$fileName 2>/dev/null` 
                  if [ -n "$fileCopy" ]; then
                        irm -f $dirName/$fileName 
                  fi
             fi
          done
      done
done
echo "complete deletion" >> "$logDir/ACORN-Moving-Data"



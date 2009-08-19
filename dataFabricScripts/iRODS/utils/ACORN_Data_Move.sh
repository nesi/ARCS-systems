#!/bin/sh

today=`date '+%Y-%m-%d'`

icp -rf /ARCS/projects/IMOS/staging/ACORN/range-time-series /ARCS/projects/IMOS/archive/ACORN
# icp -rf /ARCS/projects/IMOS/staging/ACORN/calibration-time-series /ARCS/projects/IMOS/archive/ACORN
icp -rf /ARCS/projects/IMOS/staging/ACORN/radial /ARCS/projects/IMOS/opendap/ACORN
icp -rf /ARCS/projects/IMOS/staging/ACORN/sea-state /ARCS/projects/IMOS/opendap/ACORN

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
             fi
          done
      done
done

dirName="archive opendap"
for name in $dirName
do
   for collName in `yes|iquest "SELECT COLL_NAME WHERE COLL_NAME like '/ARCS/projects/IMOS/$name/ACORN%'" |grep COLL_NAME |cut -d' ' -f3`
   do
      for collID in `yes|iquest "select COLL_ID where COLL_NAME like '$collName'" |grep COLL_ID |cut -d' ' -f3`
      do
          icd $collName
          for item in `psql ICAT -A -t -c "select data_name, modify_ts from r_data_main where coll_id = '$collID'"`
          do
             fileName=`echo $item|cut -d'|' -f1`
             modifyTime=`echo $item|cut -d'|' -f2`
             modifyDate=`iadmin ctime $modifyTime|cut -d':' -f2|cut -d'.' -f1`
             if [ "$modifyDate" = "$today" ]; then
                  irm -f $fileName
             fi
          done
      done
   done
done


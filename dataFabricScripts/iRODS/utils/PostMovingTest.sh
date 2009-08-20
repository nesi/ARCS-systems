#!/bin/sh

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
                  echo $fileName, modifyDate
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
                  echo $fileName, modifyDate
             fi
          done
      done
   done
done



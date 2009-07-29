#!/bin/sh

cp -rf /ARCS/projects/IMOS/staging/ACORN/range-time-series /ARCS/projects/IMOS/archive/ACORN
#cp -rf /ARCS/projects/IMOS/staging/ACORN/calibration-time-series /ARCS/projects/IMOS/archive/ACORN
cp -rf /ARCS/projects/IMOS/staging/ACORN/radial /ARCS/projects/IMOS/opendap/ACORN
cp -rf /ARCS/projects/IMOS/staging/ACORN/sea-state /ARCS/projects/IMOS/opendap/ACORN

for collName in `yes|iquest "SELECT COLL_NAME WHERE COLL_NAME like '/ARCS/projects/IMOS/staging/ACORN%'" |grep COLL_NAME |cut -d' ' -f3`
do
      for collID in `yes|iquest "select COLL_ID where COLL_NAME like '$collName'" |grep COLL_ID |cut -d' ' -f3`
      do
          icd $collName
          for dataName in `psql ICAT -A -t -c "select data_name from r_data_main where coll_id = '$collID'"`
          do 
            irm -f $dataName
          done
      done
done

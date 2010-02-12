#!/bin/sh

icommandsDir="/opt/iRODS/iRODS/clients/icommands/bin"
today=`date '+%Y-%m-%d'` 
curTime=`date '+%Y-%m-%d-%H-%M-%S'` 
echo $curTime  

for dirName in `ls /data/ARCS-DATA/ARCS/projects/IMOS/staging/ANFOG/PROCESSED`
do
   $icommandsDir/icp -rf -R arcs-df.ivec.org /ARCS/projects/IMOS/staging/ANFOG/PROCESSED/$dirName /ARCS/projects/IMOS/opendap/ANFOG
done
echo "complete copying to opendap"

for dirName in `ls /data/ARCS-DATA/ARCS/projects/IMOS/staging/ANFOG/RAW`
do
   $icommandsDir/icp -rf -R arcs-df.ivec.org /ARCS/projects/IMOS/staging/ANFOG/RAW/$dirName /ARCS/projects/IMOS/archive/ANFOG
done
echo "complete copying to archive"

for dirName in `ls /data/ARCS-DATA/ARCS/projects/IMOS/staging/ANFOG/JPEG`
do
   $icommandsDir/icp -rf -R arcs-df.ivec.org /ARCS/projects/IMOS/staging/ANFOG/JPEG/$dirName /ARCS/projects/IMOS/public/ANFOG
done
echo "complete copying to public"

for fileName in `find /data/ARCS-DATA/ARCS/projects/IMOS/staging/ANFOG -type f -daystart -mtime +1|cut -c16-`
do
    case $fileName in
         *PROCESSED*)
         fileCopy=`echo $fileName|cut -c45-`
         if [ -n "`ls /data/ARCS-DATA/ARCS/projects/IMOS/opendap/ANFOG/$fileCopy 2>/dev/null`" ]; then
             echo "deleted file:" $fileName `stat -c %y "/data/ARCS-DATA"$fileName`
             $icommandsDir/irm -f $fileName
         fi
         ;; 
         *RAW*)
         fileCopy=`echo $fileName|cut -c38-`
         if [ -n "`ls /data/ARCS-DATA/ARCS/projects/IMOS/archive/ANFOG/$fileCopy 2>/dev/null`" ]; then
             echo "deleted file:" $fileName `stat -c %y "/data/ARCS-DATA"$fileName`
             $icommandsDir/irm -f $fileName
         fi
         ;;
         *JPEG*)
         fileCopy=`echo $fileName|cut -c40-`
         if [ -n "`ls /data/ARCS-DATA/ARCS/projects/IMOS/public/ANFOG/$fileCopy 2>/dev/null`" ]; then
             echo "deleted file:" $fileName `stat -c %y "/data/ARCS-DATA"$fileName`
             $icommandsDir/irm -f $fileName
         fi
         ;;
    esac
done
echo "complete deletion"

#!/bin/sh
# Downloading the usage stats of all sites to local site

logDir="$IRODS_HOME/server/log"

usage()
{
echo "Usage: `basename $0` -d Path-To-DataFabric-UsageStats"
exit 1
}
if [ $# -ne 2 ] 
then
    usage
fi

while getopts d OPTION
do
   case $OPTION in
   d)  if [ ! -e $2 ]; then
           mkdir $2
       fi
     ;;
   \?) usage
      ;;
   esac
done

#Complete the copy from yesterday's XML to today's if a collection operation can not be done successfully from a site
cpXMLfile()
{
dir=$1
file=$2
year=`date '+%Y'`
month=`date '+%m'`
day=`date '+%d'`
curDate=$year-$month-$day

day=`expr "$day" - 1`
case "$day" in                
0)
month=`expr "$month" - 1`
case "$month" in           
0)
month=12
year=`expr "$year" - 1`
;;
esac
day=`cal $month $year | grep . | fmt -1 | tail -1`     
esac
dayLen=`expr length $day`
if [ $dayLen -lt 2 ]; then
   day="0$day"      
fi                       
monLen=`expr length $month`    
if [ $monLen -lt 2 ]; then
   month="0$month"
fi
lastDate=$year-$month-$day
curTime=`date '+%Y-%m-%d-%H-%M-%S'`

curXMLfile=`find $1/$2/dataFabricStats -name $2-$curDate\*.xml` 
lastXMLfile=`find $1/$2/dataFabricStats -name $2-$lastDate\*.xml`

if [ -z "$curXMLfile" ]; then
   cp $lastXMLfile $1/$2/dataFabricStats/$2-$curTime.xml
fi
}

#postfix or sendmail needs to be configured
#The file called as siteAdmins stores each site admin's email address, which is located in the path $IRODS_HOME/server/bin/usageScripts
# Each line in the file looks like irods.hpcu.uq.edu.au: Kai.Lu@arcs.org.au 
mailOut()
{
mailAddress=`cat $IRODS_HOME/server/bin/usageScripts/siteAdmins | grep $1 |awk -F: '{print $2}'`
echo "Unsuccessful in downloading usage stats from your site!" |mail -s "Usage Stats" $mailAddress  
}

#Print time to log file of usage stats
date '+%Y-%m-%d-%H-%M-%S' >> "$logDir/useLog-DataFabric"

if ! ./iadmin lz >/dev/null 2>&1; then
   echo "Something is wrong with your iRODS server!" >>  "$logDir/useLog-DataFabric"
else
   for zone in `./iadmin lz`
   do
       if ! ./iget -r -f /$zone/projects/dataFabricStats $2/$zone ; then
             echo "Unsuccessful in collecting from $zone!" >> "$logDir/useLog-DataFabric"            
             #mailOut $zone
             cpXMLfile $2 $zone
       fi
   done
   python $IRODS_HOME/server/bin/usageScripts/DBScripts/StatsDB.py $2 >> "$logDir/useLog-DataFabric" 2>> "$logDir/useLog-DataFabric"
fi

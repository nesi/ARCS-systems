#!/bin/sh
# Uploading the usage stat of local site to SRB

logDir="/usr/srb/data/log"
today=`date '+%Y-%m-%d'`
curTime=`date '+%Y-%m-%d-%H-%M-%S'`

usage()
{
echo "Usage: `basename $0` -d Path-To-Your-Zone-UsageStats"
exit 1
}
if [ $# -ne 2 ] 
then
    usage
fi

#Find local zone name
zone=`cat ~/.srb/.MdasEnv|grep 'mdasCollectionName' |awk -F/ '{print $2}'`

while getopts d OPTION
do
   case $OPTION in
   d)  # checking
       if [ ! -e $2 ]; then
            mkdir $2
       fi
     ;;
   \?) usage
      ;;
   esac
done

#postfix or sendmail needs to be configured
mailOut()
{
echo "Unsuccessful in collecting usage stats! Please check the logs." |mail -s "Usage Stats" Your-Email-Address
}

#Assume that only last five XML files are kept
days=5

#Print time to log file of usage stats
echo $curTime >> "$logDir/useLog"

#Start to collect usage stats from local MCAT
python /usr/srb/bin/usageScripts/usageFromMCAT.py > "$2/$zone-$curTime.xml" 2>>"$logDir/useLog"

#Check if the XML file is empty
if [ `ls -l "$2/$zone-$curTime.xml"|cut -d" " -f5` -eq 0 ]; then
   echo "The XML file of usage stats is empty!" >>"$logDir/useLog"
   #mailOut
   exit 2
else
   echo "Collecting usage stats from DB is completed!" >> "$logDir/useLog"
   find $2 -name $zone-$today\* ! -name *$curTime.xml|xargs rm -rf
fi

#Start to upload usage stats to local SRB
if Sinit >/dev/null 2>&1; then
       # Check if the SRB dir of storing usage stats exists 
       if [ -n "`SgetColl /$zone/projects/dataFabricStats`" ] ; then
            Srm -rf /$zone/projects/dataFabricStats
       fi
       Smkdir -p /$zone/projects/dataFabricStats

       #Find the old XML file createded $days ago
       find $usageDir -name \*xml -daystart -mtime +$days |xargs rm -rf
       Sput -r $2/*.xml /$zone/projects/dataFabricStats
       Schmod a srbAdmin srb.hpcu.uq.edu.au /$zone/projects/dataFabricStats/*.xml
else
       echo "Can not initialise the client SRB environment session!" >> "$logDir/useLog"
       #mailOut
fi

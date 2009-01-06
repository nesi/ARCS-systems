
# ----------------------------------------------------------------------------------------
# Assuming:
#   @ the admin user of iRODS is rods
#   @ the zone name starts with irods
#   @ the zone usage stats is located in the path $IRODS_HOME/server/bin/usageScripts/xml
#   @ the log file of usage stats is located in the path $IRODS_HOME/server/log
# ----------------------------------------------------------------------------------------

#!/bin/sh
# Uploading the usage stat of local site to iRODS

logDir="$IRODS_HOME/server/log"
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
zone=`cat ~/.irods/.irodsEnv|grep 'irodsZone' |awk '{print $2}'|tr -d "'"`
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

#Assume that only last five XML files are kept
days=4

#postfix or sendmail needs to be configured
mailOut()
{
echo "Unsuccessful in collecting usage stats! Please check the logs." |mail -s "Usage Stats" Your-Email-Address
}

#Print time to log file of usage stats
echo $curTime >> "$logDir/useLog"

#Start to collect usage stats from local ICAT
python usageFromICAT.py > "$2/$zone-$curTime.xml" 2>>"$logDir/useLog"

#Check if the XML file is empty
if [ `ls -l "$2/$zone-$curTime.xml"|cut -d" " -f5` -eq 0 ]; then
   echo "The XML file of usage stats is empty!" >>"$logDir/useLog"
   #mailOut
   exit 2
else
   echo "Collecting usage stats from DB is completed!" >> "$logDir/useLog"
   find $2 -name $zone-$today\* ! -name *$curTime.xml|xargs rm -rf
fi

#Remove the directory of storing usage stats in data fabric if it exists
irm -rf /$zone/projects/dataFabricStats
imkdir -p /$zone/projects/dataFabricStats

#Find the old XML file createded $days+1 ago
find $2 -name \*xml -daystart -mtime +$days|xargs rm -rf

#upload usage stats to local iRODS
iput -r $2/*.xml /$zone/projects/dataFabricStats

#The ownership is granted to rods@irods.hpcu.uq.edu.au 
ichmod -r own rods#irods.hpcu.uq.edu.au /$zone/projects/dataFabricStats

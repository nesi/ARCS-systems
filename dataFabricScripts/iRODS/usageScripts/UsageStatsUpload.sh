
# ----------------------------------------------------------------------------------------
# Assuming:
#   @ the admin user of iRODS is rods
#   @ the zone name starts with irods
#   @ the zone usage stats is located in the path $IRODS_HOME/server/bin/usageScripts/xml
#   @ the log file of usage stats is located in the path $IRODS_HOME/server/log
# ----------------------------------------------------------------------------------------
# Notes that the path may be changed for the future iRODS installation in the production machine  

#!/bin/sh
# Uploading the usage stat of local site to iRODS

IRODS_HOME="/opt/iRODS-2.0v/iRODS"
IRODS_CLIENTS="$IRODS_HOME/clients/icommands/bin"
logDir="$IRODS_HOME/server/log"
curTime=`date '+%Y-%m-%d-%H-%M-%S'`
today=`date '+%Y-%m-%d'`

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
python $IRODS_HOME/server/bin/usageScripts/usageFromICAT.py > "$2/$zone-$curTime.xml" 2>>"$logDir/useLog"

#Check if the XML file is empty
if [ `ls -l "$2/$zone-$curTime.xml"|cut -d" " -f5` -eq 0 ]; then
   echo "The XML file of usage stats is empty!" >>"$logDir/useLog"
   #mailOut
   exit 2
else
   echo "Collecting usage stats from DB is completed!" >> "$logDir/useLog"
   find $2 -name $zone-$today\* ! -name *$curTime.xml|xargs rm -rf
fi

#Ensure that iinit is already run
#There are two approaches to run iinit automatically and please choose one of them
#(1)run iinit <password>
#(2)run iinit < [file] - a text file with stored password 
#For approach 2, the full path of that file needs to be provided

#Remove the directory of storing usage stats in data fabric if it exists
$IRODS_CLIENTS/irm -rf /$zone/projects/dataFabricStats >/dev/null 2>&1
$IRODS_CLIENTS/imkdir /$zone/projects/dataFabricStats

#Find the old XML file createded $days+1 ago
find $2 -name \*xml -daystart -mtime +$days|xargs rm -rf

#upload usage stats to local iRODS
$IRODS_CLIENTS/iput -r $2/*.xml /$zone/projects/dataFabricStats

#The ownership is granted to rods@QUEST.hpcu.uq.edu.au 
$IRODS_CLIENTS/ichmod -r read rods#quest.hpcu.uq.edu.au /$zone/projects/dataFabricStats

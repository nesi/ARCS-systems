
# ----------------------------------------------------------------------------------------
# Assuming:
#   @ the admin user of iRODS is rods
#   @ the zone name is ARCS
#   @ the Data Fabric usage stats is located in the path $IRODS_HOME/server/bin/usageScripts/xml
#   @ the log file of usage stats is located in the path $IRODS_HOME/server/log
# ----------------------------------------------------------------------------------------

#!/bin/sh

IRODS_HOME="/opt/iRODS-2.0v/iRODS"
logDir="$IRODS_HOME/server/log"
curTime=`date '+%Y-%m-%d-%H-%M-%S'`
today=`date '+%Y-%m-%d'`

usage()
{
echo "Usage: `basename $0` -d Path-To-DataFabric-UsageStats"
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
            mkdir $2/$zone
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
python $IRODS_HOME/server/bin/usageScripts/usageFromICAT.py > "$2/$zone/$zone-$curTime.xml" 2>>"$logDir/useLog"

#Check if the XML file is empty
if [ `ls -l "$2/$zone/$zone-$curTime.xml"|cut -d" " -f5` -eq 0 ]; then
   echo "The XML file of usage stats is empty!" >>"$logDir/useLog"
   #mailOut
   exit 2
else
   echo "Collecting usage stats from DB is completed!" >> "$logDir/useLog"
   find $2/$zone -name $zone-$today\* ! -name *$curTime.xml|xargs rm -rf
fi


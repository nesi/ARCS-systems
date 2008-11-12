#!/bin/sh
# Downloading the usage stats of all sites to local site

logDir="/usr/srb/data/log/"

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

#postfix or sendmail needs to be configured
mailOut()
{
echo "Unsuccessful in downloading usage stats! Please check the logs." |mail -s "Usage Stats" Your-Email-Address
}

#Print time to log file of usage stats
date '+%Y-%m-%d-%H-%M-%S' >> "$logDir/useLog-DataFabric"

if Sinit >/dev/null 2>&1; then
   for zone in `Stoken Zone|grep zone_id|awk '{k=NF;if (k / 2 == 1)print $k}'`
   do
       if [ -e "$2/$zone" ]; then
            rm -rf $2/$zone
       fi
       mkdir $2/$zone
       if ! Sget /$zone/projects/dataFabricStats/* $2/$zone ; then
            echo "Unsuccessful in collecting from $zone!" >> "$logDir/useLog-DataFabric"
            #mailOut
       fi 
   done
   python /usr/bin/StatsDB.py $2 >> "$logDir/useLog-DataFabric" 2>> "$logDir/useLog-DataFabric"
else
       echo "Can not initialise the client SRB environment session!" >>  "$logDir/useLog-DataFabric"
       #mailOut
fi

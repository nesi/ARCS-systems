#!/bin/sh
IRODS_HOME="/opt/iRODS/iRODS"
icommandsDir="$IRODS_HOME/clients/icommands/bin"
logDir="$IRODS_HOME/server/log/"

export "LD_LIBRARY_PATH=/opt/vdt/globus/lib"

usage()
{
echo "Usage: `basename $0` -d ADDRESSEE"
exit 0
}

if [ $# -ne 2 ] 
then
    usage
fi

while getopts dh OPTION  
do  
   case $OPTION in  
       d)  mailAddr=$2
           ;;
       h)  usage 
           ;; 
       \?) usage  
           ;;  
   esac  
done  


#postfix or sendmail needs to be configured
mailOut()
{
echo $message |mail -s "iRODS Resource Monitoring [mesg-id=$ret_pid]" $mailAddr
}

#Print time to log file of resource monitoring cron job
date '+%Y-%m-%d-%H-%M-%S' >> "$logDir/cron_RS"

ret_pid=$$

echo $ret_pid  >> "$logDir/cron_RS"

serverState=`$IRODS_HOME/irodsctl status|grep No`
if  [ -n "$serverState" ]; then
    exit 0
fi
 
for resc in `$icommandsDir/iadmin lr`
do
    rescArray=( "${rescArray[@]}" $resc )
    statusArray=( "${statusArray[@]}" `$icommandsDir/iquest "select RESC_STATUS WHERE RESC_NAME = '$resc'" | grep RESC_STATUS | cut -c15-` )
done


$icommandsDir/irule -F $IRODS_HOME/rsmond

number_of_resources=${#rescArray[@]} 
index=0

while [ $index -lt $number_of_resources ]
do
    newStatus=`$icommandsDir/iquest "select RESC_STATUS WHERE RESC_NAME = '${rescArray[$index]}'" | grep RESC_STATUS | cut -c15-`
    if [ "$newStatus" != "${statusArray[$index]}" ]; then
       message=`echo "The resource ${rescArray[$index]} is $newStatus."`
       echo $message >> "$logDir/cron_RS"
       mailOut
    fi
    index=`expr $index + 1`
done

$icommandsDir/irule -F $IRODS_HOME/rmflush



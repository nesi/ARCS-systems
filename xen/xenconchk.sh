#!/bin/bash
# 24/04/08 WH Modified to check xenconsoled
# http://vertito.blogspot.com/2007/08/checking-daemon-service-bash-script.html
PATH=$PATH:/usr/bin:/bin:/sbin:/usr/sbin

ayos=`ps -ef|grep xenconsoled|grep -v grep|awk '{print $2}'`

if [ ! "$ayos" -gt "0" ]; then
xenconsoled --log none --log-dir /var/log/xen/console
# uncomment for notification
#echo "Restarted at $date" | mail -s "xenconsoled from server restarted" youremail@yourdomain.com
fi
exit

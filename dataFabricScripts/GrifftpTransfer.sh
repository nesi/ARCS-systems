#!/bin/sh
source /opt/vdt/setup.sh
export GLOBUS_LOCATION=/opt/vdt/globus
function usage
{
echo "Usage: GridftpTransfer <GridFtp-Server> <path/to/source/directory> <path/to/destination/directory>"
exit 1
}
if [ "$#" -ne 3 ]
then 
usage
fi
TEST=`grid-proxy-info -timeleft 2> /dev/null`
if [ "$TEST" -gt 0 ]
then
echo "Found valid proxy!"
else
echo "Please run grid-proxy-init first"
exit 1
fi
globus-url-copy -r -vb file://$2 gsiftp://$1$3

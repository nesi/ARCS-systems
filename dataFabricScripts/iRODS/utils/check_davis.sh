#!/bin/sh
# check_idavis.sh Nagios plugin for Davis.
#                 Graham Jenkins <graham@vpac.org> Feb 2010. Rev: 20100202

# Test file and contents .. adjust as appropriate
Url="https://df.arcs.org.au/ARCS/worldview/Melbourne/CityDetails.txt"
String="Victoria"

# Path, usage message
PATH=/usr/bin:/bin
[ $# != 0 ] && echo "Usage: `basename $0`" >&2 && exit 2

# Attempt to get the file and check its content
wget -q -T 25 --no-cache --no-cookies -O - $Url 2>/dev/null |
  grep -q "$String"
case $? in
  0) echo "DAVIS OK: access succeeded"   ; exit 0;;
  *) echo "DAVIS CRITICAL: access failed"; exit 2;;
esac

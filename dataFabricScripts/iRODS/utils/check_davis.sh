#!/bin/sh
# check_idavis.sh Nagios plugin for Davis.
#                 Graham Jenkins <graham@vpac.org> Feb 2010. Rev: 20100330

# Test file and contents .. adjust as appropriate
Collection="https://df.arcs.org.au/ARCS/worldview"
File="https://df.arcs.org.au/ARCS/worldview/Melbourne/CityDetails.txt"
String="Victoria"

# Path, usage message
PATH=/usr/bin:/bin
[ $# != 0 ] && echo "Usage: `basename $0`" >&2      && exit 2

# Attempt to get the file and check its content
wget -q -T 25 --no-cache --no-cookies -O - $File 2>/dev/null | grep -q "$String"
if [ $? -eq 0 ] ; then
  echo "DAVIS OK: access succeeded"                  ; exit 0
fi

# If we failed, perform a reset on the Collection and try again
wget -q -T 25 --no-cache --no-cookies -O - $Collection?reset >/dev/null 2>&1
sleep 5
wget -q -T 25 --no-cache --no-cookies -O - $File 2>/dev/null | grep -q "$String"

# If we got it this time, flag as WARNING; else flag as CRITICAL 
if [ $? -eq 0 ] ; then
  echo "DAVIS WARNING: access succeeded after reset" ; exit 1 
else
  echo "DAVIS CRITICAL: access failed"               ; exit 2
fi

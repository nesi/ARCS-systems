#!/bin/sh
# check_idavis.sh Nagios plugin for Davis.
#                 Graham Jenkins <graham@vpac.org> Feb 2010. Rev: 20101210

# Test file and contents .. adjust as appropriate
Collection="https://df.arcs.org.au/ARCS/worldview"
File="https://df.arcs.org.au/ARCS/worldview/Melbourne/CityDetails.txt"
String="Victoria"

# Allowable time between successful accesses (mins)
Minutes=12

# Path, usage message
PATH=/usr/bin:/bin
[ $# != 0 ] && echo "Usage: `basename $0`" >&2      && exit 2

# Attempt to get the file and check its content; exit on success
cd
StatFile=.`basename $0`.STAT
if wget -q -T 25 --no-cache --no-cookies --no-check-certificate \
     -O - $File 2>/dev/null | grep -q "$String" ; then
  touch $StatFile 2>/dev/null && echo "DAVIS OK: access succeeded" && exit 0
fi

# Otherwise check how long since we last saw success
if [ `find . -maxdepth 1 -name $StatFile -mmin -$Minutes | wc -w` -gt 0 ] ; then
  # Recently .. issue a warning and attempt reset
  echo "DAVIS WARNING: access failed, attempting reset"
  wget -q -T 25 --no-cache --no-cookies --no-check-certificate \
      -O /dev/null ${Collection}?reset 2>/dev/null 
  exit 1 
else
  # Not recently .. it's critical!
  echo "DAVIS CRITICAL: last successful access was more than $Minutes mins ago"
  exit 2
fi

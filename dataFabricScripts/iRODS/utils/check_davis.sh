#!/bin/sh
# check_idavis.sh Nagios plugin for Davis.
#                 Graham Jenkins <graham@vpac.org> Feb 2010. Rev: 20101202

# Test file and contents .. adjust as appropriate
Collection="https://df.arcs.org.au/ARCS/worldview"
File="https://df.arcs.org.au/ARCS/worldview/Melbourne/CityDetails.txt"
String="Victoria"

# Path, usage message
PATH=/usr/bin:/bin
[ $# != 0 ] && echo "Usage: `basename $0`" >&2      && exit 2

# Attempt to get the file and check its content
LockDir=~/.`basename $0`.LCK
wget -q -T 25 --no-cache --no-cookies -O - $File 2>/dev/null | grep -q "$String"
if [ $? -eq 0 ] ; then
  rmdir $LockDir 2>/dev/null
  echo "DAVIS OK: access succeeded"                  ; exit 0
fi

if mkdir $LockDir >/dev/null 2>&1 ; then
  echo "DAVIS WARNING: access failed once"           ; exit 1 
else
  echo "DAVIS CRITICAL: access failed more than once"; exit 2
fi

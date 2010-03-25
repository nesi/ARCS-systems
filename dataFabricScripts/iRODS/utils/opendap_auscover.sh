#!/bin/sh
# opendap_auscover.sh  Sets ACLs for AusCover files/directories so that the
#                      OpenDAP application can access them.
#                      Pauline Mak, Sep. 2009.
#                      graham@vpac.org Rev: 20100325 

# Anti-simultaneity check
ShortName=`basename $0 | cut -c 1-15`
if [ "`pgrep -o $ShortName`" -ne $$ ] ; then
  logger -t `basename $0` "Detected running process"; exit 1
fi 

# Record the start time, ensure that Stamp File is available
if ! TempFile=`mktemp` >/dev/null 2>&1 ; then
  logger -t `basename $0` "TempFile failure"        ; exit 1
else
  trap 'rm -f $TempFile' 0 1 2 3 4 15
fi
StampFile=~/.`basename $0`
[ -w $StampFile ] || touch -t 201003230900 $StampFile

# Directories, User
vaultDir=/data/ARCS-DATA
tree="ARCS projects AusCover"
user=jetty

# Set ACLs
for dir in $tree ; do
  cd $vaultDir || exit 1
  setfacl -m u:$user:--x $dir
  vaultDir=$dir
done

cd AusCover || exit 1
setfacl -m u:$user:r-x -m m::r-x opendap
setfacl -d -m u:$user:r-x -m m::r-x opendap

cd opendap || exit 1
find -newer $StampFile |
while read Object ; do
  if   [ -f "$Object" ] ; then
    setfacl    -m u:$user:r-- -m m::r-- "$Object"
  elif [ -d "$Object" ] ; then
    setfacl    -m u:$user:r-x -m m::r-x "$Object"
    setfacl -d -m u:$user:r-x -m m::r-x "$Object"
  fi
done

# Update the Stamp File and exit
mv -f $TempFile $StampFile 2>/dev/null && exit 0 || exit 1

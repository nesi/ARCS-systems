#!/bin/sh
# bulkCompare.sh  Compare bulk-data-transfer programs.
#                 <graham@vpac.org> June 2010. Rev: 20100604

# Options
Aggres=5
Count=1
Params="-pp -p 4 -cc 2 -g2 -q"
while getopts a:c:u Option; do
  case $Option in
    a) Aggres=$OPTARG;;
    c) Count=$OPTARG;;
    u) Params="-udt -pp -p 2 -cc 2 -g2 -q";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 0 \) ]                  &&
  echo "  Usage: `basename $0` [-a N] [-c M] [-u]" >&2 && exit 2

# Directories, remote user 
#SOURCE=/usr/local/bin
SOURCE=/data/GLOBUSORG/Graham/640m
#DESTIN=/home/graham/ASTRO/Graham/640m
DESTIN=/data/tmp/Graham/640m
USER=graham@gridftp-test.ivec.org

# PATH, aliases
export GLOBUS_LOCATION=/opt/globus-5.0.1
export PATH=$GLOBUS_LOCATION/bin:$PATH
Xopts="-o \"UserKnownHostsFile /dev/null\" -o \"StrictHostKeyChecking no\""
alias ssu="ssh -X $Xopts" scu="scp $Xopts"

for C in `seq 1 $Count` ; do
  # Clean the destination, send files using fdt.jar
  ssu ${USER} "rm -rf $DESTIN; mkdir $DESTIN"
  echo --
  echo "Using: java -jar fdt.jar -ss 32M -iof 4 .. " 
  time          java -Xms256m -Xmx256m -jar `which fdt.jar` \
   -sshKey ~/.ssh/id_dsa -p 40100 -noupdates -ss 32M -iof 4 \
   $SOURCE/* ${USER}:$DESTIN </dev/null >/dev/null 2>&1
  # Clean the destination, send files using globus-url-copy
  ssu ${USER} "rm -rf $DESTIN; mkdir $DESTIN"
  echo --
  echo "Using: globus-url-copy $Params .."
  wc -c ${SOURCE}/*
  time globus-url-copy $Params \
         "file:///${SOURCE}/" "sshftp://${USER}/${DESTIN}/"
  echo --
  # Clean the destination, send files using movedat
  ssu ${USER} "rm -rf $DESTIN; mkdir $DESTIN"
  ssu ${USER} \
    "/home/graham/ExpeDat/Server\ Files/servedat -p 40100 -a 5 / 2>/dev/null" \
                                                              >/dev/null 2>&1 &
  sleep 20
  echo "Using: movedat -p 40100 -b 65536 -a $Aggres -q .."
  time /opt/ExpeDat/Client\ Files/movedat -p 40100 -b 65536 -a $Aggres -q \
        $SOURCE/* ${USER}:$DESTIN/ 
  ssu ${USER} "pkill servedat"        >/dev/null 2>&1
done

#!/bin/sh
# gloPut7t.sh  Copies files in a designated directory to a remote server.
#              Version 7 uses globus-url-copy with sshftp. Timeout parameter
#              and stall-time limit are used to circumvent extended lockups.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20091216

# Default-batch-size, environment
BATCH=16       # Adjust as appropriate
STALL=60
export GLOBUS_LOCATION=/opt/globus-4.2.1
export GLOBUS_TCP_PORT_RANGE=40000,40100 GLOBUS_UDP_PORT_RANGE=40000,40100
export PATH=$GLOBUS_LOCATION/bin:$PATH GLOBUS_CALLBACK_POLLING_THREADS=1

# Usage, alias
Params="-pp -p 4"
while getopts b:us Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    u) Params="-udt -p 1";;
    s) Skip="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ $# -ne 3 ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/February09/v252l/Mopra"
    echo "Options: -b n .. use a batch-size of 'n' (default 16)"
    echo "         -s   .. skip files whose names begin with a period"
    echo "         -u   .. use 'udt' protocol"                ) >&2 && exit 2
alias ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  rm -f $TmpFil $LisFil
  echo "$@"; exit $Code
}

# Globus-URL-Copy function; file list is 1st param
doGlobus() {
  Secs=`wc -c \`awk '{print $1}'<$1|cut -c 8-\`|
        awk 'END {print int(60+$(NF-1)/10000000)}'`
  [ -z "$Udt" ] && Secs=`expr $Secs + $Secs`
  echo "`date '+%a %T'` .. Pid: $$ .. Limit: `expr $Secs / 60` mins .. Files:"
  wc -c `awk '{print $1}' < $1 | cut -c 8-`
  globus-url-copy -q -t $Secs -st $STALL $Params -cc 2 -f $1
  echo
  >$1
  [ -x "$TmpFil" ]                        || fail 0 "Graceful Termination"
}

# Create destination directory if required, ensure that we can write to it 
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
ssu $2 "mkdir -p -m 775 $3"   2>/dev/null || fail 1 "Remote-directory problem"
ssu $2 "chmod 775       $3"   2>/dev/null

# Create temporary files, set traps
TmpFil=`mktemp` && chmod a+x $TmpFil      || fail 1 "Temporary file problem"
LisFil=`mktemp`                           || fail 1 "Temporary file problem"
trap "" 0 1 2 3 4 14 15
trap "chmod a-x $TmpFil ; echo Break detected .. wait" CONT
trap 'Params="-pp  -p 4"; echo Switched to TCP..'      USR1
trap 'Params="-udt -p 1"; echo Switched to UDT..'      USR2

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -CONT $$"
echo "To switch to TCP/UDT mode enter: kill -USR1/USR2 $$"
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # Generate a list of the files already copied successfully
  ssu $2 "ls -aogl $3 2>/dev/null">$TmpFil 2>/dev/null||fail 1 "Remote lst prob"
  for File in `[ -z "$Skip" ] && find $1 -maxdepth 1 -type f \
                              || find $1 -maxdepth 1 -type f ! -name ".*"` ; do
    [ -r "$File"    ]             || continue
    LocName=`basename $File`
    LocSize=`ls -ogl $File | awk '{print $3}'`
    RemSize=`awk '{if($NF==locname){print $3;exit 0}}' locname=$LocName<$TmpFil`
    if [ "$LocSize" != "$RemSize" ]; then
      Flag=Y
      echo "file://$File sshftp://$2$3/" >> $LisFil
      [ "`cat $LisFil 2>/dev/null | wc -l`" = $BATCH ] && doGlobus $LisFil
    fi
  done
  [ "`cat $LisFil 2>/dev/null | wc -l`" != 0 ] && doGlobus $LisFil
done

# All done, adjust permissions and exit
ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "No more files to be copied!"

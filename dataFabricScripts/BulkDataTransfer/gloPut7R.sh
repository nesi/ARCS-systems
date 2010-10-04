#!/bin/sh
# gloPut7R.sh  Recursively copies files to a remote server.
#              Requires threaded globus-url-copy; uses sshftp.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20101004

# Default-batch-size, environment
BATCH=16       # Adjust as appropriate
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage, ssh parameters
Params="-p 4"
Days=32767
while getopts b:d:sru Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    d) Days=$OPTARG;;
    s) Skip="Y";;
    r) Order="-r";;
    u) Params="-udt -p 2";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /mnt/pulsar/MTP26M" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/Aidan"
    echo "Options: -b n      .. use a batch-size of 'n' (default 16)"
    echo "         -d m      .. only transfer files changed in last 'm' days"
    echo "         -s        .. skip files whose names begin with a period"
    echo "         -r        .. reverse order"
    echo "         -u        .. use 'udt' protocol"              ) >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'
[ `uname -s` = SunOS ] && Wc="du -h" || Wc="wc -c"

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  rm -f $LisFil $RemFil
  echo "$@"; exit $Code
}

# Globus-URL-Copy function; file list is 1st param
doGlobus() {
  echo "`date '+%a %T'` .. Pid: $$ .. Files:"
  eval $Wc `awk '{print $1}' < $1 | cut -c 8-`
  globus-url-copy -q -cd $Params -cc 2 -fast -f $1
  echo
  >$1
  [ -x "$1" ]                             || fail 0 "Graceful Termination"
}

# Create destination directory if required, ensure that we can write to it 
eval $Ssu $2 /bin/date</dev/null>/dev/null 2>&1 ||fail 1 "Remote-userid invalid"
eval $Ssu $2 "mkdir -p -m 775 $3"   2>/dev/null
eval $Ssu $2 "test -w         $3"   2>/dev/null ||fail 1 "Remote-dir'y problem"

# Create temporary files, set traps
RemFil=`mktemp` && chmod a+x $RemFil      || fail 1 "Temporary file problem"
LisFil=`mktemp` && chmod a+x $LisFil      || fail 1 "Temporary file problem"
trap "chmod a-x $LisFil ; echo Break detected .. wait" TERM
trap 'Params="     -p 4"; echo Switched to TCP..'      USR1
trap 'Params="-udt -p 2"; echo Switched to UDT..'      USR2

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -TERM $$"
echo "To switch to TCP/UDT mode enter: kill -USR1/USR2 $$"
while [ -x $RemFil ] ; do
  chmod a-x $RemFil # Clear the "copy done" flag
  echo "Generating a list of files to be copied .. wait .."
  # List filename/size couplets for files already in remote directory
  ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no" $2 \
        "cd $3 && find . -type f          | xargs ls -lLA 2>/dev/null" |
         awk '{print $NF, $5}' >$RemFil 2>/dev/null
  cd $1 && find . -type f -mtime -${Days} | xargs ls -lLA 2>/dev/null  |
         awk '{print $NF, $5}' | sort $Order |
  while read FileWithSize; do
    grep -q "$FileWithSize" $RemFil                    && continue
    File="`echo $FileWithSize | awk '{print $1}'`"
    [ \( ! -f "$1/$File" \) -o \( ! -r "$1/$File" \) ] && continue
    case "`basename $File`" in
      .* ) [ -n "$Skip" ] && continue ;;
    esac
    chmod a+x $RemFil # Set the "copy done" flag
    echo "file://$1/$File sshftp://$2$3/$File"|sed -e 's_/\./_/_'>>$LisFil
    [ "`cat $LisFil 2>/dev/null | wc -l`" -eq $BATCH ] && doGlobus $LisFil
  done
  [ "`cat $LisFil 2>/dev/null | wc -l`" -ne 0 ] && doGlobus $LisFil
done

# All done, adjust permissions and exit
eval $Ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "No more files to be copied!"

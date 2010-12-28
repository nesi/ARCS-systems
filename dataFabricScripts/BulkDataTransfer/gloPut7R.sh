#!/bin/sh
# gloPut7R.sh  Recursively copies files to a remote server.
#              Requires threaded globus-url-copy; uses sshftp.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20101228

# Default-batch-size, concurrency, environment; adjust as appropriate
BATCH=16; CONCUR=2
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage, ssh parameters
Params="-p 4"
Match="."
while getopts b:c:d:m:srux Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    c) CONCUR=$OPTARG;;
    d) Days="-mtime -$OPTARG";;
    m) Match=$OPTARG;;
    s) Skip="Y";;
    r) Order="-r";;
    u) Params="-udt -p 2";;
    x) MaxDep="-maxdepth 1";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /mnt/pulsar/MTP26M" \
                 "graham@pbstore.ivec.org" \
                 "/pbstore/as03/pulsar/MTP26M"
    echo "Options: -b l      .. use a batch-size of 'l' (default $BATCH)"
    echo "         -c m      .. do 'm' concurrent transfers (default $CONCUR)"
    echo "         -d n      .. only transfer files changed in last 'n' days"
    echo "         -m String .. send only files whose names contain 'String'"
    echo "         -s        .. skip files whose names begin with a period"
    echo "         -x        .. don't descend through directories"
    echo "         -r        .. reverse order"
    echo "         -u        .. use 'udt' protocol"              ) >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'
[ `uname -s` = SunOS ] && Wc="du -h" || Wc="wc -c"

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  rm -f $LisFil
  echo "$@"; exit $Code
}

# Globus-URL-Copy function; file list is 1st param
doGlobus() {
  echo "`date '+%a %T'` .. Pid: $$ .. Files:"
  eval $Wc `awk '{print $1}' < $1 | cut -c 8-`
  if ! globus-url-copy -q -cd $Params -cc $CONCUR -fast -f $1 ; then
    echo "Failed; sleeping for 5 mins!"; sleep 300
  fi
  echo
  >$1
  [ -x "$1" ]                             || fail 0 "Graceful Termination"
}

# Create destination directory if required, ensure that we can write to it 
eval $Ssu $2 /bin/date</dev/null>/dev/null 2>&1 ||fail 1 "Remote-userid invalid"
eval $Ssu $2 "mkdir -p -m 2775 $3"  2>/dev/null
eval $Ssu $2 "test -w          $3"  2>/dev/null ||fail 1 "Remote-dir'y problem"

# Create temporary file, set traps
LisFil=`mktemp` && chmod a+x $LisFil      || fail 1 "Temporary file problem"
trap "chmod a-x $LisFil ; echo Break detected .. wait" TERM
trap 'Params="     -p 4"; echo Switched to TCP..'      USR1
trap 'Params="-udt -p 2"; echo Switched to UDT..'      USR2

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -TERM $$"
echo "To switch to TCP/UDT mode enter: kill -USR1/USR2 $$"
Flag=Y
while [ -n "$Flag" ] ; do
  Flag= # Clear the "copy done" flag
  echo "Generating a list of files to be copied .. wait .."
  for File in `
  ( # List files already in remote directory, with blank line at end
    eval $Ssu $2 "cd $3 \&\& find . -type f \| xargs ls -lLA 2>/dev/null"
    echo 
    # List files to be copied from local directory, then process the output
    cd $1 && find . ${MaxDep} -type f ${Days} | xargs ls -lLA 2>/dev/null
  ) | awk '{ if (NF==0)      {Local="Y"; next  }
             if (Local=="Y") {locsiz[$NF]="s"$5}
             else            {remsiz[$NF]="s"$5}
           } # s-prefix is inserted so zero-length files are treated correctly
       END { for (file in locsiz) {
               if (locsiz[file]!=remsiz[file]) {print file}
             }
           }' | grep $Match | sort $Order`; do
    [ \( ! -f "$1/$File" \) -o \( ! -r "$1/$File" \) ] && continue
    case "`basename $File`" in
      .* ) [ -n "$Skip" ] && continue ;;
    esac
    Flag=Y # Set the "copy done" flag
    echo "file://$1/$File sshftp://$2$3/$File"|sed -e 's_/\./_/_'>>$LisFil
    [ "`cat $LisFil 2>/dev/null | wc -l`" -eq $BATCH ] && doGlobus $LisFil
  done
  [ "`cat $LisFil 2>/dev/null | wc -l`" -ne 0 ] && doGlobus $LisFil
done

# All done, adjust permissions and exit
User="`echo $2 | awk -F@ '{if(NF>1)print $1}'`"
[ -z "$User" ] && User=$LOGNAME
eval $Ssu $2 "find $3 -type d -user $User \| xargs chmod  2775" 2>/dev/null
eval $Ssu $2 "find $3 -type f -user $User \| xargs chmod   664" 2>/dev/null
fail 0 "No more files to be copied!"

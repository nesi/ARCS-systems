#!/bin/sh
# gloPut7T.sh  Copies files in a designated directory to a remote server.
#              Requires threaded globus-url-copy; uses sshftp.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20101112

# Default-batch-size, environment
BATCH=16       # Adjust as appropriate
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage, ssh parameters
Params="-p 4"
Skip="A"
Match="."
while getopts b:usrm: Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    u) Params="-udt -p 2";;
    s) Skip=;;
    r) Order="-r";;
    m) Match=$OPTARG;;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/February09/v252l/Mopra"
    echo "Options: -b n      .. use a batch-size of 'n' (default 16)"
    echo "         -r        .. reverse order"
    echo "         -s        .. skip files whose names begin with a period"
    echo "         -m String .. send only files whose names contain 'String'"
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
  if ! globus-url-copy -q $Params -cc 2 -fast -f $1 ; then
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
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # List filename/size couplets in remote and local directories; if a couplet
  # appears once then it hasn't been copied properly, so add filename to list
  for File in `( eval $Ssu $2 "ls -lL$Skip $3 2>/dev/null"
                               ls -lL$Skip $1 2>/dev/null ) |
      awk '{print \$NF, \$5}' | sort $Order | uniq -u |
      awk '{print \$1}'       |                  uniq | grep $Match`; do
    [ \( ! -f "$1/$File" \) -o \( ! -r "$1/$File" \) ] && continue
    Flag=Y
    echo "file://$1/$File sshftp://$2$3/" >> $LisFil
    [ "`cat $LisFil 2>/dev/null | wc -l`" -eq $BATCH ] && doGlobus $LisFil
  done
  [ "`cat $LisFil 2>/dev/null | wc -l`" -ne 0 ] && doGlobus $LisFil
done

# All done, adjust permissions and exit
eval $Ssu $2 "chmod -f g+rw $3/*"
fail 0 "No more files to be copied!"

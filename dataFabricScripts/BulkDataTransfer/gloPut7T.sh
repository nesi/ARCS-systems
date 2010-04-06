#!/bin/sh
# gloPut7T.sh  Copies files in a designated directory to a remote server.
#              Requires threaded globus-url-copy (GT 5.x.x); uses sshftp.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20100407

# Default-batch-size, environment
BATCH=16       # Adjust as appropriate
[ -d /opt/globus-5/bin ] && export GLOBUS_LOCATION=/opt/globus-5 \
                         || export GLOBUS_LOCATION=/opt/globus-4.2.1
export GLOBUS_TCP_PORT_RANGE=40000,40100 GLOBUS_UDP_PORT_RANGE=40000,40100
export PATH=$GLOBUS_LOCATION/bin:$PATH

# Usage, alias
Params="-pp -p 4"
Skip="A"
while getopts b:us Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    u) Params="-udt -pp -p 2";;
    s) Skip=;;
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
  rm -f $LisFil
  echo "$@"; exit $Code
}

# Globus-URL-Copy function; file list is 1st param
doGlobus() {
  echo "`date '+%a %T'` .. Pid: $$ .. Files:"
  wc -c `awk '{print $1}' < $1 | cut -c 8-`
  globus-url-copy -q $Params -cc 2 -st 60 -g2 -f $1
  echo
  >$1
  [ -x "$1" ]                             || fail 0 "Graceful Termination"
}

# Create destination directory if required, ensure that we can write to it 
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
ssu $2 "mkdir -p -m 775 $3"   2>/dev/null || fail 1 "Remote-directory problem"
ssu $2 "chmod u+rw      $3"   2>/dev/null || fail 1 "Remote-directory problem"

# Create temporary file, set traps
LisFil=`mktemp` && chmod a+x $LisFil      || fail 1 "Temporary file problem"
trap "chmod a-x $LisFil ; echo Break detected .. wait"     CONT
trap 'Params="     -pp -p 4"; echo Switched to TCP..'      USR1
trap 'Params="-udt -pp -p 2"; echo Switched to UDT..'      USR2

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -CONT $$"
echo "To switch to TCP/UDT mode enter: kill -USR1/USR2 $$"
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # List filename/size couplets in remote and local directories; if a couplet
  # appears once then it hasn't been copied properly, so add filename to list
  for File in `( ssu $2 "ls -l$Skip $3 2>/dev/null"
                         ls -l$Skip $1 2>/dev/null ) |
      awk '{print \$9, \$5}' | sort | uniq -u | awk '{print \$1}' | uniq`; do
    [ \( ! -f "$1/$File" \) -o \( ! -r "$1/$File" \) ] && continue
    Flag=Y
    echo "file://$1/$File sshftp://$2$3/" >> $LisFil
    [ "`cat $LisFil 2>/dev/null | wc -l`" = $BATCH ] && doGlobus $LisFil
  done
  [ "`cat $LisFil 2>/dev/null | wc -l`" != 0 ] && doGlobus $LisFil
done

# All done, adjust permissions and exit
ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "No more files to be copied!"

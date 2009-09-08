#!/bin/sh
# gloPut7.sh   Copies files in a designated directory to a remote server.
#              Version 7 uses globus-url-copy with sshftp to transfer
#              files concurrently with log-monitoring for time-out purposes.
#              Graham.Jenkins@arcs.org.au  April 2009. Rev: 20090908

# Default-batch-size, environment
BATCH=16       # Adjust as appropriate
export GLOBUS_LOCATION=/opt/globus-4.2.1 PATH=/opt/globus-4.2.1/bin:$PATH
export GLOBUS_TCP_PORT_RANGE=40000,41000 GLOBUS_UDP_PORT_RANGE=40000,41000

# Usage, alias
while getopts b:us Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    u) Udt="-udt";;
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
  rm -f $TmpFil $LisFil $LogFil
  echo "$@"; exit $Code
}

# Progressive kill function; parameters are Pid and wait-time after each signal
doKill() {
  for Signal in 2 15 ; do
    echo " .. doing:  kill -$Signal $1"
    kill -$Signal $1 2>/dev/null
    for Seq in `seq $2`; do
      ps -f -p $1 >/dev/null 2>&1 || return
    done
  done
  kill -9 $1 2>/dev/null
}

# Globus-URL-Copy function; file list is 1st param
doGlobus() {
  globus-url-copy -vb $Udt -pp -p 4 -cc 2 -f $1 >$LogFil&
  echo "`date '+%a %T'` .. Pid: $$ .. Logfile: $LogFil .. Files:"
  wc -c `awk '{print $1}' < $1 | cut -c 8-79`
  # Timeout if, for 60 secs, trnsfr-rate remains zero or logfile doesn't change
  Rcoun=0; Scoun=0; OldSize=0
  while ps -f -p $! >/dev/null 2>&1 ; do
    sleep 1
    Rate=`tr -d '[\000-\011]'<$LogFil 2>/dev/null | sed 's/\r/\n/g' | 
      awk '{if($0~/sec inst$/) {print $(NF-2)} }' | tail -1`
    [ -z "$Rate" ] && Rate="0.00"
    NewSize="`wc -c $LogFil | awk '{print $1}'`"
    [ "$NewSize" != "$OldSize" ] && Scoun=0 && OldSize="$NewSize" \
                                            || Scoun=`expr 1 + $Scoun` 
    [ "$Rate"    != "0.00"     ] && Rcoun=0 || Rcoun=`expr 1 + $Rcoun`  
    # echo "DB1:  Rate: $Rate  NewSize: $NewSize  Rcoun: $Rcoun  Scoun: $Scoun"
    [ $Rcoun -le  60           ] && [ $Scoun -le 60 ] && continue
    echo "Timeout! Killing Pid: $!"; doKill $! 60 ; break
  done
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
LogFil=`mktemp`                           || fail 1 "Temporary file problem"
trap "" 0 1 2 3 4 14 15
trap "chmod a-x $TmpFil; echo Break detected .. wait" CONT
trap 'Udt=""           ; echo Switched to TCP..'      USR1
trap 'Udt="-udt"       ; echo Switched to UDT..'      USR2

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -CONT $$"
echo "To switch to TCP/UDT mode enter: kill -USR1/USR2 $$"
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # Generate a list of the files already copied successfully
  ssu $2 "ls -aogl $3 2>/dev/null">$TmpFil 2>/dev/null||fail 1 "Remote list prob"
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

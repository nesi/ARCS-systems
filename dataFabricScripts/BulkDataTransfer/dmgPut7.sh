#!/bin/sh
# dmgPut7.sh   'Dmget' recursive version of gloPut7.sh ..
#              Recursively copies files in a designated directory to a remote
#              server using globus-url-copy with sshftp to transfer
#              files concurrently with log-monitoring for time-out purposes.
#              Graham.Jenkins@arcs.org.au  June 2009. Rev: 20090624

# Default-batch-size, environment
BATCH=8        # Adjust as appropriate
GLOBUS_LOCATION=/opt/globus-4.2.1 PATH=/opt/globus-4.2.1/bin:$PATH
LD_LIBRARY_PATH=/opt/globus-4.2.1/lib:$LD_LIBRARY_PATH
GLOBUS_TCP_PORT_RANGE=40000,41000 GLOBUS_UDP_PORT_RANGE=40000,41000
export GLOBUS_LOCATION PATH LD_LIBRARY_PATH GLOBUS_TCP_PORT_RANGE \
                                            GLOBUS_UDP_PORT_RANGE
# Usage, alias
while getopts b:u Option; do
  case $Option in
    b) BATCH=$OPTARG;;
    u) Udt="-udt";;
  esac
done
shift `expr $OPTIND - 1`
[ $# -ne 3 ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /library/radio_astronomy/pulsar" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/graham"
    echo "Options: -b n .. use a batch-size of 'n' (default 16)"
    echo "         -u   .. use 'udt' protocol"                ) >&2 && exit 2
alias ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
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

# Globus-URL-Copy function; parameters are source and destination URLs
doGlobus() {
  LogFil=`mktemp`                           || fail 1 "Temporary file problem"
  globus-url-copy -vb $Udt -pp -p 4 $1 $2 >$LogFil &
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
  rm -f $LogFil
}

# Check that ssh works for us and that source directory is OK
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
cd  $1                                    || fail 1 "Source-directory problem"

# Start recovering files, create temporary file, set traps
( dmfind $1 -state OFL -o -state PAR | dmget 2>/dev/null & )
TmpFil=`mktemp`                           || fail 1 "Temporary file problem"
trap "rm -f $TmpFil; echo Terminating" 1 2 3 4 14 15

# Loop until no more files need to be copied
Flag=Y
while [ -n "$Flag" ] ; do
  Flag= 
  echo; echo "Making destination directories .."
  find . -type d -exec echo mkdir -p -m 775 $3/{} \; 2>/dev/null | ssu $2    \
                            2>/dev/null      || fail 1 "Remote-directory problem" 
  echo "Listing files which have already been copied to: $TmpFil"
  ssu $2 "cd $3 && find . -type f 2>/dev/null -exec wc -c {} \; 2>/dev/null" \
     2>/dev/null >$TmpFil                    || fail 1 "Remote-listing problem"
  echo "Copying files .."
  for File in `find . -type f 2>/dev/null | sort` ; do
    [ -r "$File"    ]             || continue
    [ ! -r "$TmpFil" ] && echo Waiting && wait && exit 0
    LocSize=`wc -c $File 2>/dev/null | awk '{print $1}'`
    RemSize=`awk '{if($NF==locname){print $1;exit 0}}' locname=$File<$TmpFil`
    if [ "$LocSize" != "$RemSize" ]; then
      Flag=Y
      echo "`date '+%a %T'` $File `wc -c <$File` `dmattr -a state $File`" 
      DirName=`dirname $File`
      ( dmget $File 2>/dev/null  # Check that we can read the entire file
        dmattr -a state $File | egrep "information|DUL|REG" >/dev/null 2>&1 &&
        doGlobus `echo "file://$1/$File sshftp://$2$3/$DirName/"|sed 's_/\./_/_g'`||\
        echo " .. $File is not available"
      ) &
      until [ `jobs | wc -l` -lt $BATCH ]; do
        sleep 1
      done
    fi
  done
  wait
done

# All done
echo "No more files to be copied!" && rm -f $TmpFil && exit 0

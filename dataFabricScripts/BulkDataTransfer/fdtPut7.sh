#!/bin/sh
# fdtPut7.sh   Copies files in a designated directory to a remote server using
#              FDT over a designated port. Needs Java 1.5 embedded or better.
#              'fdt.jar' and 'java' need to be in PATH and executable.
#              Graham.Jenkins@arcs.org.au  July 2009. Rev: 20090804

# Default port, ssh-key and batch-size; adjust as appropriate
PORT=80; KEY=~/.ssh/id_dsa; BATCH=16; export PORT KEY BATCH

# Options
while getopts p:k:b: Option; do
  case $Option in
    p) PORT=$OPTARG;;
    k) KEY=$OPTARG;;
    b) BATCH=$OPTARG;;
  esac
done
shift `expr $OPTIND - 1`

# Usage, alias
[ $# -ne 3 ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "accumulator@arcs-df.ivec.org \\"
    echo "                       /data/ASTRO-TRANSFERS/February09/v252l/Mopra"
    echo "Options: -p m .. use port 'm' (default $PORT)"
    echo "         -b N .. use batch-size N (default $BATCH)"
    echo "         -k keyfile .. use 'keyfile' (default $KEY)" ) >&2 && exit 2
alias ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  rm -f $TmpFil
  echo "$@"; exit $Code
}

# Java FDT invocation
doJava () {
  java -Xms256m -Xmx256m -jar `which fdt.jar` -sshKey $KEY -p $PORT \
      -ss 32M -iof 4 $1/* $2:$3 </dev/null >/dev/null 2>&1
  echo
}

# Check jar-file, create destination directory if required, 
java -jar `which fdt.jar` -V 2>/dev/null  || fail 1 "Problem with java/fdt.jar"
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
ssu $2 "mkdir -p -m 775 $3"   2>/dev/null || fail 1 "Remote-directory problem"
ssu $2 "chmod 775 `dirname $3`" 2>/dev/null 

# Create temporary file and directory
TmpFil=`mktemp`                           || fail 1 "Temporary-file problem"
TmpDir=`mktemp -d`                        || fail 1 "Temporary-dir'y problem"
trap "rm -rf $TmpFil $TmpDir; exit 0" 0 1 2 3 4 14 15

# Loop until no more files need to be copied
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # Generate a list of the files already copied successfully
  ssu $2 "ls -ogl $3 2>/dev/null">$TmpFil 2>/dev/null||fail 1 "Remote list prob"
  for File in `find $1 -maxdepth 1 -type f | sort` ; do
    [ -r "$File"    ]             || continue
    LocName=`basename $File`
    LocSize=`ls -ogl $File | awk '{print $3}'`
    RemSize=`awk '{if($NF==locname){print $3;exit 0}}' locname=$LocName<$TmpFil`
    if [ "$LocSize" != "$RemSize" ]; then
      Flag=Y
      echo "`date '+%a %T'` .. `wc -c $File` .. Pid: $$"
      ln -s $File $TmpDir/
      [ `ls $TmpDir/ | wc -w` = $BATCH ] && ( doJava $TmpDir $2 $3 ; rm -f $TmpDir/* ) 
    fi
  done
  [ `ls $TmpDir/ | wc -w` != 0 ] && ( doJava $TmpDir $2 $3 ; rm -f $TmpDir/* )
done

# All done
fail 0 "No more files to be copied!"

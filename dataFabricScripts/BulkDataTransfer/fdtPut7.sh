#!/bin/sh
# fdtPut7.sh   Copies files in a designated directory to a remote server using
#              FDT over a designated port. Needs Java 1.6 or better.
#              'fdt.jar' and 'java' need to be in PATH and executable.
#              Graham.Jenkins@arcs.org.au  July 2009. Rev: 20100617

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
  echo "$@"; exit $Code
}

# Java FDT invocation
doJava () {
  [ `ssu $2 "df -P $3" 2>/dev/null | awk '{if ($5~/%/){print $5;exit}}' |
     tr -d %` -gt 95 ] && fail 1 "Remote filesystem nearing capacity; aborted!"
  java -Xms256m -Xmx256m -jar `which fdt.jar` -sshKey $KEY -p $PORT \
       -noupdates -ss 32M -iof 4 -notmp -rCount 2 -wCount 2         \
                                          $1/* $2:$3 </dev/null >/dev/null 2>&1
  [ -n "$Abort" ] && rm -rf $1 && fail 0 "Cleaning Up .."
  rm -f $1/*
  echo
}

# Check jar-file, create destination directory if required, 
java -jar `which fdt.jar` -V 2>/dev/null  || fail 1 "Problem with java/fdt.jar"
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
ssu $2 "mkdir -p -m 775 $3"   2>/dev/null
ssu $2 "test -w         $3"   2>/dev/null || fail 1 "Remote-directory problem"

# Create temporary directory, set exit trap
TmpDir=`mktemp -d`                        || fail 1 "Temporary-dir'y problem"
trap "Abort=Y ; echo Wait .." USR1

# Loop until no more files need to be copied
echo "To Terminate gracefully,  enter: kill -USR1 $$"
Abort=
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # List filename/size couplets in remote and local directories; if a couplet
  # appears once then it hasn't been copied properly, so add filename to list
  for File in `( ssu $2 "ls -lL $3 2>/dev/null"
                         ls -lL $1 2>/dev/null ) |
      awk '{print \$NF, \$5}' | sort | uniq -u | awk '{print \$1}' | uniq`; do
    [ \( ! -f "$1/$File" \) -o \( ! -r "$1/$File" \) ] && continue  
    Flag=Y
    [ `ls $TmpDir/ | wc -w` -eq 0 ] && echo "== `date '+%a %T'` .. Pid: $$ =="
    wc -c $1/$File
    ln -s $1/$File $TmpDir/
    [ `ls $TmpDir/ | wc -w` -eq $BATCH ] && doJava $TmpDir $2 $3
  done
  [ `ls $TmpDir/ | wc -w` -ne 0 ] && doJava $TmpDir $2 $3
done

# All done, adjust permissions and exit
ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "No more files to be copied!"

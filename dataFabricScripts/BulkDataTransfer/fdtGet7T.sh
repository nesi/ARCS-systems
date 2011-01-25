#!/bin/sh
# fdtGet7T.sh  Copies files from a designated directory on a remote server using
#              FDT over a designated port. Needs Java 1.6. Beta version only!
#              'fdt.jar' and 'java' need to be in PATH and executable.
#              Graham.Jenkins@arcs.org.au Jan. 2011; Rev: 20110125

# Default port and ssh-key; adjust as appropriate
PORT=80; KEY=~/.ssh/id_dsa; export PORT KEY

# Options
while getopts p:k:b:r Option; do
  case $Option in
    p) PORT=$OPTARG;;
    k) KEY=$OPTARG;;
    r) Order="-r";;
  esac
done
shift `expr $OPTIND - 1`

# Usage, alias
[ $# -ne 3 ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data2/arcs/vt16a/Hobart" \
                 "root@gridftp-test.ivec.org /data/tmp/Graham/vt16a"
    echo "Options: -p m .. use port 'm' (default $PORT)"
    echo "         -r   .. reverse order"
    echo "         -k keyfile .. use 'keyfile' (default $KEY)" ) >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  echo "$@"; exit $Code
}

mkdir -p $1 2>/dev/null
test -w  $1 || fail 1 "Local directory problem!"

# Java Invocation
Failures=0
for File in `
  ( cd  $1 &&  find -L . -maxdepth 1 -type f | xargs ls -lLA 2>/dev/null
    echo
    eval $Ssu $2 \
    "cd $3\&\& find -L . -maxdepth 1 -type f\| xargs ls -lLA 2>/dev/null"
  ) | awk '{ if (NF==0)       {Remote="Y"; next}
             if (Remote=="Y") {if ("X"locsiz[$NF]!="X"$5) {print $NF}}
             else             {locsiz[$NF]=$5}
           }' | sort $Order`; do
  echo -n "`date '+%a %T'` .. $File .. "
  if java -Xms256m -Xmx256m -jar `which fdt.jar` -sshKey $KEY -p $PORT \
    -noupdates -ss 32M -iof 4 -notmp $2:$3/$File $1/ </dev/null >/dev/null 2>&1;
                                                                            then
    echo OK
  else
    echo Failed; Failures=`expr 1 + $Failures`; sleep 5
  fi
done

fail 0 "Completed pass; $Failures errors"

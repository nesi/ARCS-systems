#!/bin/sh
# gloPut8T.sh  Copies files in a designated directory to a remote server.
#              Requires GT 5.0.2 threaded globus-url-copy; uses sshftp.
#              For Solaris, use 'ksh' instead of 'sh'.
#              Graham.Jenkins@arcs.org.au  June 2010. Rev: 20100703

# Environment, etc.
for Dir in globus-5 globus-5.0.2 globus-5.0.1 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && export GLOBUS_LOCATION=/opt/$Dir && break
done
export PATH=$GLOBUS_LOCATION/bin:$PATH

# Usage, alias
Skip="A"; Sort="sort -r"
Params="-v -cd -cc 2 -fast -p 4 -sync -sync-level 1"
while getopts sru Option; do
  case $Option in
    s) Skip=;;
    r) Sort="cat";;
    u) Params="-v -cd -cc 2 -udt -fast -p 2 -sync -sync-level 1";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/May10/v252l/Mopra"
    echo "Options: -s   .. skip files whose names begin with a period"
    echo "         -r   .. reverse order"
    echo "         -u   .. use 'udt' protocol"                ) >&2 && exit 2
alias ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  echo "$@"; exit $Code
}

# Check ssh key validity
ssu $2 /bin/date</dev/null>/dev/null 2>&1  || fail 1 "Remote-userid is invalid"

# Create a link directory with links to the source files that are readable
SouDir=`mktemp -d`&&trap 'rm -rf $SouDir' 0|| fail 1 "Temporary dir'y problem"
for F in `ls -1L$Skip "$1" | $Sort`; do
  [ \( -r "$1/$F" \) -a \( -f "$1/$F" \) ] && ln -s "$1/$F" $SouDir
done

# Loop until no more files need to be copied from the link directory
while : ; do
  Pass=`expr $Pass + 1`; [ $Pass -gt 20 ] && fail 1 "Too many failures!"
  echo "`date '+%a %T'` .. Determining files to be copied (Pass $Pass)"
  globus-url-copy $Params "file://$SouDir/" "sshftp://$2/$3/" && break || echo
  sleep $Pass
done

# All done, adjust permissions and exit
ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "`date '+%a %T'` .. No more files to be copied!"

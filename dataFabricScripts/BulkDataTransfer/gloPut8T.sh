#!/bin/sh
# gloPut8T.sh  Copies files in a designated directory to a remote server.
#              Requires GT 5.0.2 threaded globus-url-copy; uses sshftp.
#              For Solaris, use 'ksh' instead of 'sh'.
#              Graham.Jenkins@arcs.org.au  June 2010. Rev: 20100630

# Environment, etc.
for Dir in globus-5 globus-5.0.2 globus-5.0.1 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && export GLOBUS_LOCATION=/opt/$Dir && break
done
export PATH=$GLOBUS_LOCATION/bin:$PATH

# Usage, alias
Skip="A"
Params="-v -cc 2 -g2 -pp -p 4 -sync -sync-level 1"
while getopts su Option; do
  case $Option in
    s) Skip=;;
    u) Params="-v -cc 2 -g2 -udt -fast -pp -p 2 -sync -sync-level 1";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data/xraid0/v252l" \
                 "accumulator@arcs-df.ivec.org" \
                 "/data/ASTRO-TRANSFERS/February09/v252l/Mopra"
    echo "Options: -s   .. skip files whose names begin with a period"
    echo "         -u   .. use 'udt' protocol"                ) >&2 && exit 2
alias ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Failure/cleanup function; parameters are exit-code and message
fail() {
  Code=$1; shift
  echo "$@"; exit $Code
}

# Create destination directory if required, ensure that we can write to it 
ssu $2 /bin/date</dev/null>/dev/null 2>&1 || fail 1 "Remote-userid is invalid"
ssu $2 "mkdir -p -m 775 $3"   2>/dev/null
ssu $2 "test -w         $3"   2>/dev/null || fail 1 "Remote-directory problem"

# Create a link directory with links to the source files that are readable
SouDir=`mktemp -d`&&trap 'rm -rf $ErrFil' 0||fail 1 "Temporary dir'y problem"
for F in `ls -1L$Skip "$1"`; do
  [ \( -r "$1/$F" \) -a \( -f "$1/$F" \) ] && ln -s "$1/$F" $SouDir
done

# Loop until no more files need to be copied from the link directory
ErrFil=`mktemp` && trap 'rm -f $ErrFil' 0 || fail 1 "Temporary file problem"
SleTim=0
until grep -q "No files matched the source url." $ErrFil ; do
  head -3 $ErrFil; sleep $SleTim; SleTim=`expr 1 + $SleTim`; echo
  [ $SleTim -gt 20 ]                      && fail 1 "Too many failures!"
  echo "`date '+%a %T'` .. Determining files to be copied."
  globus-url-copy $Params "file://$SouDir/" "sshftp://$2/$3/" 2>$ErrFil && break
done

# All done, adjust permissions and exit
ssu $2 "chmod -R g+rw $3" 2>/dev/null
fail 0 "`date '+%a %T'` .. No more files to be copied!"

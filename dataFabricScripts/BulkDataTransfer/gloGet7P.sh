#!/bin/bash
# gloGet7P.sh  Gets files (recursively) from a remote server. Uses
#              Globus XIO Pipe-Open-Driver to circumvent problems which
#              can arise when incoming connection restrictions prevent
#              usage of Mode E connections.
#              Ref: "Globus XIO Pipe Open Driver ..", Raj Kettimuthu et al,
#              TeraGrid '11, July 2011, Salt lake City.
#              Graham Jenkins <graham@vpac.org> Sep. 2011, Rev: 20110923

# Environment
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
GLOBUS_FTP_CLIENT_SOURCE_PASV=Y
export GLOBUS_LOCATION PATH GLOBUS_FTP_CLIENT_SOURCE_PASV

# Usage, alias
while getopts u Option; do
  case $Option in
    u) Param="-u";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` local-directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data2/arcs" "graham@cortex.ivec.org" \
             "/pbstore/groupfs/astrotmp/as03/VLBI/Archive/SSWC_archive"
    echo "Options: -u        .. use udt" 
  )  >&2 && exit 2

# Create destination directory, do the transfer
# See: www.mcs.anl.gov/~bresnaha/Stretch/
echo "`date '+%a %T'` Transferring files .."
mkdir -pv $1
globus-url-copy -v -c $Param -src-fsstack popen:argv="#/bin/tar#cf#-#-C#$3#." \
                             -dst-fsstack popen:argv="#/bin/tar#xf#-#-C#$1"   \
                                sshftp://$2/src sshftp://`hostname`///tmp/dst
echo "`date '+%a %T'` All Done!"
exit 0

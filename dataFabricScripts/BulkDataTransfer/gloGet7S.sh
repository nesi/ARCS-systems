#!/bin/bash
# gloGet7S.sh  Gets files (recursively) from a remote server. Not suitable
#              for transferring lots of small files over a link which won't
#              accept connections on ports in GLOBUS_TCP_PORT_RANGE, since
#              it uses a new connection for each transfer and exhausts all
#              available ports.
#              Graham Jenkins <graham@vpac.org> Aug. 2010, Rev: 20110609

# Environment
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage, alias
CONCUR=2
while getopts fc: Option; do
  case $Option in
    c) CONCUR=$OPTARG;;
    f) FAST="-fast";;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "Usage: `basename $0` local-directory remote-userid remote-directory"
    echo " e.g.: `basename $0` /data2/arcs" "graham@pbstore.ivec.org" \
                              "/pbstore/as03/VLBI/Archive/SSWC_archive"
    echo "Options: -c m      .. do 'm' concurrent transfers (default $CONCUR)"
    echo "         -f        .. use '-fast' parameter (to re-use sockets)"
  )  >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Make local directory, then loop until no more files need to be copied
mkdir -p $1
ListFile=`mktemp`; chmod a+x $ListFile; trap 'rm -f $ListFile' 0
LinkDir=`eval $Ssu $2 mktemp -d 2>/dev/null`
trap 'eval $Ssu $2 rm -rf $LinkDir 2>/dev/null' 0
while [ -x $ListFile ] ; do
  chmod a-x $ListFile
  echo "`date '+%a %T'` Generating a list of files to be copied .. wait .."
  eval $Ssu $2 "cd $3 \&\& find -L . -type f\|xargs ls -lLA 2>/dev/null">$ListFile
  [ `wc -c < $ListFile` -lt 1 ] && echo "Failed!" >&2 && exit 2
  for File in `
  ( cd $1 && ( find -L . -type f; echo /dev/null ) | xargs ls -lLA 2>/dev/null
    echo
    cat $ListFile 
  ) | awk '{ if (NF==0)      {Local="Y"; next}
             if (Local=="Y") {if ("X"remsiz[$NF]!="X"$5) {print $NF} }
             else            {remsiz[$NF]=$5}
           }' | sort`; do
    echo mkdir -p $LinkDir/`dirname $File`
    echo ln -s $3/$File $LinkDir/$File
    chmod a+x $ListFile
  done | eval $Ssu $2 >/dev/null 2>&1
  echo "`date '+%a %T'` Commencing transfer .. wait .."
  globus-url-copy -r -v -nodcau -cd -cc $CONCUR $FAST sshftp://$2/$LinkDir/ \
                                                      file://$1/ 2>/dev/null
  eval $Ssu $2 "rm -rf $LinkDir/\*" 2>/dev/null
done
echo "ALL DONE"
exit 0

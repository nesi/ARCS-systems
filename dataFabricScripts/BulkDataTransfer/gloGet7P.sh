#!/bin/bash
# gloGet7P.sh  Gets files (recursively) from a remote server. Can use Globus
#              XIO Pipe-Open-Driver to circumvent problems which might arise
#              when incoming restrictions limit number of connections.
#              Ref: "Globus XIO Pipe Open Driver ..", Raj Kettimuthu et al,
#              TeraGrid '11, July 2011, Salt lake City.
#              Graham Jenkins <graham@vpac.org> Sep. 2011, Rev: 20110929

# Note: For pipe operations, 'exec' line in remote 'sshftp' file must
# include: '-fs-whitelist popen,file,ordering -popen-whitelist tar:/bin/tar'

# Environment
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
GLOBUS_FTP_CLIENT_SOURCE_PASV=Y
export GLOBUS_LOCATION PATH GLOBUS_FTP_CLIENT_SOURCE_PASV

# Usage, alias
Match="."
while getopts um:c: Option; do
  case $Option in
    u) Param="-u"     ;;
    m) Match=$OPTARG  ;;
    c) Concur=$OPTARG ;;
   \?) Bad="Y"        ;;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` local-directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data2/arcs" "graham@cortex.ivec.org" \
             "/pbstore/groupfs/astrotmp/as03/VLBI/Archive/SSWC_archive"
    echo "Options: -u        .. use udt" 
    echo "         -c m      .. do 'm' concurrent transfers, no pipe-drivers"
    echo "         -m String .. send only files whose names contain 'String'" 
  )  >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Make local directory, then loop until no more files need to be copied
mkdir -pv $1
ListFil=`mktemp`; trap 'rm -f $ListFil' 0
LinkDir=`eval $Ssu $2 mktemp -d 2>/dev/null`
trap 'eval $Ssu $2 rm -rf $LinkDir 2>/dev/null' 0
Count=0
while : ; do
  # Sleep at start of each pass after 3 to avoid DOS-denial blocking
  Count=`expr 1 + $Count`
  [ "$Count" -gt 3 ] && echo "Sleeping 5 mins .." && sleep 300
  # Create links to files which need to be copied and are readable
  echo "`date '+%a %T'` Generating a list of files to be copied .. wait .."
  eval $Ssu $2 \
   "cd $3 \&\& find -L . -type f\|xargs ls -lLA 2\>/dev/null">$ListFil
  [ `wc -c < $ListFil` -lt 1 ] && echo "Failed .." && continue
  for File in `
  ( cd $1 && ( find -L . -type f; echo /dev/null ) | xargs ls -lLA 2>/dev/null
    echo
    cat $ListFil 
  ) | awk '{ if (NF==0)      {Local="Y"; next}
             if (Local=="Y") {if ("X"remsiz[$NF]!="X"$5) {print $NF} }
             else            {remsiz[$NF]=$5}
           }' | grep $Match | sort`; do
    echo mkdir -p $LinkDir/`dirname $File`
    echo "[ -r $3/$File ] && ln -s $3/$File $LinkDir/$File"
  done | eval $Ssu $2 >/dev/null 2>&1
  [ `eval $Ssu $2 "find $LinkDir ! -type d" | wc -l` -lt 1 ] && break
  # Do the transfer! See: www.mcs.anl.gov/~bresnaha/Stretch/
  echo "`date '+%a %T'` Commencing transfer .. wait .."
  if [ -z "$Concur" ]; then 
    globus-url-copy -v -c -nodcau $Param \
      -src-fsstack popen:argv="#/bin/tar#chf#-#-C#$LinkDir#." \
      sshftp://$2/src file:///dev/stdout | /bin/tar xvf - -C $1
  else
    globus-url-copy -v -c -nodcau $Param -cd -cc $Concur -g2 -r \
      sshftp://$2/$LinkDir/ file://$1/
  fi
  eval $Ssu $2 "rm -rf $LinkDir/\*" 2>/dev/null
done
echo "`date '+%a %T'` All Done!"
exit 0

#!/bin/bash
# gloGet7P.sh  Gets files (recursively) from a remote server. Can use
#              remote-end-pipe to circumvent problems which might arise when
#              incoming restrictions limit number of connections. Accommodates
#              subdirectories and files whose names contain spaces.
#              Graham Jenkins <graham@vpac.org> Sep. 2011, Rev: 20121208

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
while getopts ufm:c: Option; do
  case $Option in
    u) Udt="-u";;
    f) Fast="-fast -pp -p 8";;
    m) Match=$OPTARG;;
    c) Concur=$OPTARG;;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 3 \) ] &&
  ( echo "  Usage: `basename $0` local-directory remote-userid remote-directory"
    echo "   e.g.: `basename $0` /data2/arcs" "graham@cortex.ivec.org" \
             "/pbstore/groupfs/astrotmp/as03/VLBI/Archive/SSWC_archive"
    echo "Options: -u        .. use udt" 
    echo "         -f        .. use 'fast' transfers, no pipe-drivers"
    echo "         -c m      .. do 'm' concurrent transfers, no pipe-drivers"
    echo "         -m String .. send only files whose names contain 'String'" 
  )  >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# For 'fast' transfers, ensure that correct network address is used
if [ -n "$Fast" ] ; then
  export \
  GLOBUS_FTP_CLIENT_DATA_IP=`host $HOSTNAME|awk '{if($0~/address/)print $NF}'`
  [ -z "$Concur" ] && echo "Setting '-c 1' .." && Concur=1
fi

# Make local directory, then loop until no more files need to be copied
mkdir -pv "$1"
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
  eval $Ssu $2 "/bin/sh" >$ListFil 2>/dev/null <<-EOF
	cd $3 && find -L . -type f | perl -lne 'print \$_,"|",-s \$_ if -r \$_'
	EOF
  [ `wc -c < $ListFil` -lt 1 ] && echo "Failed .." && continue
  ( cd $1     && find -L . -type f | perl -lne 'print $_,"|",-s $_ if -r $_'
    cat $ListFil 
  ) | sort | uniq -u | grep $Match | awk -F"|" '{
    dest=linkdir"/`dirname \""$1"\"`"
    print "[ -r \""srcdir"/"$1"\" ] && "
    print "mkdir -p \""dest"\" && "
    print "ln -s \""srcdir"/"$1"\" \""dest"\""}' srcdir="$3" linkdir="$LinkDir"|
    eval $Ssu $2 >/dev/null 2>&1
  [ `eval $Ssu $2 "find $LinkDir ! -type d" 2>/dev/null| wc -l` -lt 1 ] && break
  # Do the transfer! See: www.mcs.anl.gov/~bresnaha/Stretch/
  echo "`date '+%a %T'` Commencing transfer .. wait .."
  if [ -z "$Concur" ]; then 
    globus-url-copy -v -c -nodcau $Udt \
      -src-pipe "/bin/tar chf - -C $LinkDir ." \
      sshftp://$2/src - | /bin/tar xvf - -C $1
  else
    globus-url-copy -v -c -nodcau $Udt $Fast -cd -cc $Concur -r \
      sshftp://$2/$LinkDir/ file://$1/
  fi
  eval $Ssu $2 "rm -rf $LinkDir/\*" 2>/dev/null
done
echo "`date '+%a %T'` All Done!"
exit 0

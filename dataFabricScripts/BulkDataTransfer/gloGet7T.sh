#!/bin/bash
# gloGet7T.sh  Gets files (recursively) from a remote server. Rate
#              restriction is used to circumvent ssh-attack mechanisms. 
#              Graham Jenkins <graham@vpac.org> Aug. 2010, Rev: 20110602

# Usage, alias
[ $# -ne 3 ] && 
  ( echo "Usage: `basename $0` local-directory remote-userid remote-directory"
    echo " e.g.: `basename $0` /data2/arcs" "graham@pbstore.ivec.org" \
                              "/pbstore/as03/VLBI/Archive/SSWC_archive"
  )  >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Environment
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Loop until no more files need to be copied
ListFile=`mktemp`; trap 'rm -f $ListFile' 0
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
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
    Flag=Y
    Start=`date +%s`
    globus-url-copy -q -st 30 -nodcau -cd sshftp://$2/$3/$File file://$1/$File
    while [ $((`date +%s`-$Start)) -lt 5 ] ; do 
      sleep 1
    done
    echo `date '+%a %T'` `wc -c $1/\$File | sed 's_/\./_/_'`
  done
done
echo "ALL DONE"
exit 0

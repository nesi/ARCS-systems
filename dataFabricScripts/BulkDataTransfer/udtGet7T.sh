#!/bin/bash
# udtGet7T.sh  Gets files (recursively) from a remote server. Uses UDT
#              'receive-file', must have 'send-file $PORT' running at server.
#              Ref:     http://sourceforge.net/projects/udt-java/ 
#              Caution: Experimental, no authentication!
#              Graham Jenkins <graham@vpac.org> Aug. 2010, Rev: 20110603

# Usage, alias
[ $# -ne 3 ] && 
  ( echo "Usage: `basename $0` local-directory remote-userid remote-directory"
    echo " e.g.: `basename $0` /data2/arcs" "graham@pbstore.ivec.org" \
                              "/pbstore/as03/VLBI/Archive/SSWC_archive"
  )  >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Path, port; adjust as necessary
PATH=$HOME/java/bin:$HOME/udt/bin:$PATH
PORT=40099

# Loop until no more files need to be copied
ListFile=`mktemp`; trap 'rm -f $ListFile' 0
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "`date '+%a %T'` Generating a list of files to be copied .. wait .."
  eval \
    $Ssu $2 "cd $3 \&\& find -L . -type f\|xargs ls -lLA 2>/dev/null">$ListFile
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
    mkdir -p `dirname $1/$File`
    receive-file \
      `echo $2|awk -F@ '{print $2}'` $PORT $3/$File $1/$File >/dev/null 2>&1
    echo `date '+%a %T'` `wc -c $1/\$File | sed 's_/\./_/_'`
  done
done
echo "ALL DONE"
exit 0

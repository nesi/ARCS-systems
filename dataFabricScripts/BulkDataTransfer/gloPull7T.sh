#!/bin/sh
# gloPull7T.sh  Pulls files from a remote server. Beta Version!
#               Graham Jenkins <graham@vpac.org> Aug. 2010, Rev: 20100818

# Usage, alias
[ $# -ne 3 ] && 
  ( echo "Usage: `basename $0` local-directory remote-userid remote-directory"
    echo " e.g.: `basename $0` /data1/ab12" "accumulator@arcs-df.ivec.org" \
                              "/opt/ASTRO-TRANSFERS/ab12" ) >&2 && exit 2
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no"'

# Environment
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Loop until no more files need to be copied
Flag=Y
while [ -n "$Flag" ] ; do
  Flag=
  echo "Generating a list of files to be copied .. wait .."
  # List filename/size couplets in remote and local directories; if a couplet
  # appears once then it hasn't been copied properly, so add filename to list
  for File in `( eval $Ssu $2 "ls -lL $3 2>/dev/null"
                               ls -lL $1 2>/dev/null ) |
      awk '{print \$NF, \$5}' | sort | uniq -u |
      awk '{print \$1}'              | uniq`     ; do
    eval $Ssu $2 "test -r $3/$File" 2>/dev/null && FLAG=Y || continue
    # Maintain pipeline of several jobs
    ( # Do character-count to ensure files are available on disk
      RemSiz=`eval $Ssu $2 "wc -c \< $3/$File" 2>/dev/null`
      echo `date '+%a %T'` $3/$File $RemSiz
      # Mode E won't work with some firewalls; use basic options
      globus-url-copy -q -cd -st 2400 -nodcau  \
        sshftp://$2/$3/$File file://$1/ ) &
    until [ `jobs 2>&1 | wc -l` -lt 4 ] ; do
      sleep 1
    done
  done
  wait
done
echo "ALL DONE"
exit 0

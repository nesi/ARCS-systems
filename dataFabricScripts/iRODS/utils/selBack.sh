#!/bin/sh
# selBack.sh	Uses 'ibun' to backup collections whose metadata contains
#		an attribute 'Backup' with value 'Yes'. Such collections must
#		be readable by the 'rods' user. If there's also an 'Email'
#		attribute messages, will be sent to the associated value.
#		This program should be executed at COB each weekday; backup
#		files are named according to day of the week.
#		Graham Jenkins <graham@vpac.org> May 2009; Rev: 20091117

# Destination directory, environment, usage
DESTIN=/ARCS/backup					# Adjust as necessary
. /etc/profile
[ $# -lt 1 ] && ( echo "Usage: `basename $0` Resource [ReplicaResource]"
  echo " e.g.: `basename $0` arcs-df.vpac.org arcs-df.ivec.org") >&2 && exit 2
! icd >/dev/null 2>&1 && echo "Connection to server failed"        >&2 && exit 2
[ "`iuserinfo 2>/dev/null | awk '/^name:/ {print \$2}'`" != "rods" ] \
             &&  echo "You must the logged in as the 'rods' user!" >&2 && exit 2
imkdir -p $DESTIN
Resource=$1; shift

# Process those directories with 'Backup' attribute 'Yes'
Seq=0
imeta qu -C Backup '=' Yes | grep '^collection: ' | sed 's/collection: //' |
while read Line; do
  Seq=`expr 1 + $Seq`
  tarFile="$DESTIN/`echo \"'\"\"$Line\"\"'\" | tr ' ' '^' | tr '/' '_' |
                                       tr -d \"'\"`.`date +%a`.tar"
  echo "Backing up iRODS collection: $Line"; echo "   to: $tarFile"
  irm -f "$tarFile" >/dev/null 2>&1
  Flag="Succeeded"
  if ibun -f -R $Resource -cDtar "$tarFile" "$Line"; then
    for Replica in $* ; do
      irepl -Q -R $Replica "$tarFile" || Flag="Failed"
    done
  else
    Flag="Failed"
  fi
  eMail="`imeta ls -C \"\$Line\" Email | awk '/^value:/ {print $2}'`"
  [ -n "$eMail" ] && ( ( echo "Backup $Flag for iRODS Collection: $Line"
                         [ "$Flag" = "Succeeded" ] && ils -l "$tarFile" ) |
                       Mail -s "iRODS Backup $Flag .. `date +%s`.$Seq" $eMail )
  echo   "Backup $Flag for iRODS Collection: $Line"
  [ "$Flag" = "Succeeded" ] && ils -l "$tarFile"
  echo
done

exit 0

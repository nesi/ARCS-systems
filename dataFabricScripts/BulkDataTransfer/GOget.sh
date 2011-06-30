#!/bin/sh
# GOGet.sh  Uses Globus Online to get entire directories from a remote machine.
#           You must have a Grid Certificate whose DN is mapped to a userid on
#           whichever machine(s) aren't running Globus Connect.
#           Graham.Jenkins@arcs.org.au June 2011. Rev: 20110630.
#           Ref: https://www.globusonline.org/2011/06/12/\
#                advice-from-the-experts-ensuring-data-integrity/#more-5003

# Sync. default, Usage, etc.
Sync=2 # Adjust as appropriate
User=$LOGNAME
while getopts s:u: Option; do
  case $Option in
    s) Sync=$OPTARG;;
    u) User=$OPTARG;;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 2 \) ] &&
  (echo "  Usage: `basename $0` remote-endpoint/path local-endpoint/path"
   echo "   e.g.: `basename $0` hovsi/exports/xraid/Ar_1/vt14j \\"
   echo "            pbstore/pbstore/as03/ARCS-TRANSFERS/June11/vt14j/Hobart"
   echo
   echo "Options: -s n      .. use 'n' as sync-parameter (default '$Sync')"
   echo "         -u user   .. Globus Online identity (default '$User')" 
   echo
   echo "  Notes: 1. You may need to start Globus Connect at one endpoint."
   echo "         2. Non-GC endpoints must be activated before execution" 
   echo "            thus: cd /tmp; nohup globusconnect -start >/dev/null 2>&1"
   echo "         3. To transfer part of a remote directory, create a temporary"
   echo "            directory containing symbolic links to required files."
  ) >&2 && exit 2
GO=$User@cli.globusonline.org
Ssu='ssh -o"UserKnownHostsFile /dev/null" -o"StrictHostKeyChecking no" $GO'

# Failure function; parameters are exit-code and message
fail () {
  Code=$1; shift; echo "$@"; exit $Code
}

# Execute the following loop until all transfers have been completed
while : ; do
  # Get a Task Id and activate any Globus Connect endpoint
  echo "`date '+%a %T'` $1 => $2 (sync=$Sync) .."
  TaskId=`eval $Ssu transfer --generate-id 2>/dev/null` || \
    fail 2 "Problem executing: ssh $GO .. aborting!" 
  for Path in "$1" "$2"; do
    EndPoint="`echo $Path | awk -F/ '{print \$1}'`"
    eval $Ssu endpoint-list -f subjects $EndPoint 2>/dev/null | 
      grep "/OU=Globus Connect Service/" >/dev/null &&
        eval $Ssu endpoint-activate $EndPoint 2>/dev/null
  done
  # Initiate a transfer and await completion
  echo "$1/ $2/ -r -s $Sync" | eval $Ssu transfer --taskid=$TaskId -d 7d
  [ -t ] && eval $Ssu wait $TaskId || eval $Ssu wait -q $TaskId
  # Get transfer details and check
  Details="`eval $Ssu details -Ocsv -ffiles,files_skipped $TaskId | head -1`"
  Files="`echo $Details   | awk -F, '{print $1}'`"
  Skipped="`echo $Details | awk -F, '{print $2}'`"
  echo "`date '+%a %T'` Total Files: $Files .. Files Skipped: $Skipped"; echo
  [ "$Files" -eq "$Skipped" ] && [ -n "$Files" ] && break
  [ -n "$Pass1" ] && echo "Pausing for 1 min .." && sleep 60 || Pass1=Y 
done 2>/dev/null

# All done, adjust permissions and exit
Dir=`echo $2 | sed 's_./_:/_' | awk -F: '{print $2}'`
echo "Transfers completed, adjusting permissions in directory: $Dir"
find $Dir -type d -user $LOGNAME | xargs chmod g+rws 2>/dev/null
find $Dir -type f -user $LOGNAME | xargs chmod   664 2>/dev/null
fail 0 "`date '+%a %T'` All done!"

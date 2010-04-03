#!/bin/sh
# koaList.sh    Prepares a list of files suitable for feeding to a datakoa
#               or Globus.org transfer engine.
#               Graham.Jenkins@arcs.org.au April 2010. Rev: 20100402

# Usage, option-processing
while getopts i Option; do
  case $Option in
    i) Include="Y";;
   \?) Bad="Y"    ;;
  esac
done
shift `expr $OPTIND - 1`
if [ \( -n "$Bad" \) -o \( $# -ne 2 \) ]; then
  (echo "  Usage: `basename $0` [-i] sourceDir destinationDir"
   echo "   e.g.: `basename $0` foo:/data/$LOGNAME/orig bar:/data/$LOGNAME/copy"
   echo "Options: -i .. include files which aren't readable" ) >&2 
  exit 2
fi

# If a hostname is missing, insert the name of this host
echo "$1" | grep -q ":" && Source="$1" || Source=`hostname -f`:"$1"
echo "$2" | grep -q ":" && Destin="$2" || Destin=`hostname -f`:"$2"

# Extract the source-directory name and list the files thereunder
cd "`echo \"$Source\" | awk -F: '{print $2}'`" 
find . -depth -type f 2>/dev/null | cut -c 3- |
while read Line ; do
  if [ \( -r "$Line" \) -o \( -n "$Include" \) ] ; then
    echo "\"$Source/$Line\" \"$Destin/$Line\""
  else 
    echo "SKIPPED \"$Line\"" >&2
  fi 
done
exit 0

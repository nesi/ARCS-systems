#!/bin/sh
# RepliCheck.sh  Replica confirmation script; prints names of files which don't
#                have replicas.
#                Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20091105

# Usage check
[ -z "$1" ] &&
  ( echo "Usage: `basename $0` Collection"
    echo " e.g.: `basename $0` \"/ARCS/projects/Large Apes\""
    echo 
    echo "Note : To replicate files found by this script, pipe its output thus:"
    echo "     .. | sed 's/^/irepl -MBTQv -R ARCS-FABRIC /' | sh" ) >&2 &&exit 2
! iadmin lu >/dev/null 2>&1 &&
  echo "It seems that you don't have 'iadmin' execute rights; this will" &&
  echo "restrict you to checking collections that you own .."

# Check that the designated collection can be seen
! ils "$1" 2>/dev/null | head -1 |grep "^/" |grep ":$" >/dev/null && 
  echo "$1 is not a collection that's visible to you!" >&2 && exit 2

# List all files with full collection path, print those that appear only once
ils -lr "$1" | awk '{
  if ($1~"^/") {    # Extract collection names from records starting in "/".
    Dir=substr($0,1,length-1)
  }
  else {
    if ($1!="C-") {  # Extract file names from non-collection records, using 
      count=NF       # string operations to preserve spaces therein.
      while ( (NF>(count-6)) || ($0~/^ /) ) {$0=substr($0,2)}
      print "\""Dir"/"$0"\""  
    }
  }
}' | sort | uniq -u

exit 0

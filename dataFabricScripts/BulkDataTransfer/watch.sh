#!/bin/ksh
# watch.sh   Basic watch program for Solaris  
#            Graham Jenkins <graham@vpac.org> May 2010. Rev: 20100518

# 'count' subroutine
count() {
  j=0
  while [ j -lt $1 ] ; do
    j=`expr 1 + $j`
    echo $j
  done
}

# Options, Usage
secs=2
while getopts n: Option; do
  case $Option in
    n) secs=$OPTARG;;
   \?) Bad="Y"     ;;
  esac
done
shift `expr $OPTIND - 1`
if [ \(  -n "$Bad" \) -o \( -z "$@" \) ] ; then
  ( echo "Usage: `basename $0` [ -n secs] Command"
    echo " e.g.: `basename $0` -n 1 \"ls -lt | head -19\"" ) >&2
  exit 2
fi

# Define the array of lines, clear the screen, set trap
rows=`tput lines`
rows=`expr $rows - 1`
for k in `count $rows`; do
  oldline[$k]=""
done
tput clear
trap "clear; exit 0" 0 1 2 3 4 14 15

# Loop forever, re-drawing the lines that changed during each pass 
while : ; do
  tput cup 0 0; tput el; print -nR "Every ${secs}s: ""$@"
  cols=`tput cols`
  tput cup 0 `expr $cols - 29`; print -nR " "; date
  eval "$@" | 
  for k in `count $rows`; do
    read newline[$k]
  done
  for k in `count $rows`; do
    if [ "${newline[k]}" != "${oldline[k]}" ] ; then
      tput cup $k 0; tput el; print -nR "${newline[k]}"
      oldline[k]="${newline[k]}"
    fi
  done
  sleep $secs
done

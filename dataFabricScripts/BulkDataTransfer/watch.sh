#!/bin/ksh
# watch.sh   Basic watch program for Solaris  
#            Graham Jenkins <graham@vpac.org> May 2010. Rev: 20101023

# 'count' subroutine
count() {
  j=0
  while [ j -lt $1 ] ; do
    j=`expr 1 + $j`
    echo $j
  done
}

# Options, Usage, Exit trap
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
trap "tput clear; exit 0" 0

# Loop forever, re-drawing the lines that changed during each pass 
oldrows=-1; oldcols=-1
while : ; do
  # If the number of rows/cols changed, clear screen, clear all history
  rows=`tput lines`; rows=`expr $rows - 1`; cols=`tput cols`
  if [ \( $rows -ne $oldrows \) -o \( $cols -ne $oldcols \) ]; then
    tput clear
    oldrows=$rows; oldcols=$cols
    for k in `count $rows`; do
      oldline[$k]=""
    done
  fi
  tput cup 0 0; tput el; print -nR "Every ${secs}s: ""$@"
  tput cup 0 `expr $cols - 29`; print -nR " "; date
  eval "$@" | 
  for k in `count $rows`; do
    read newline
    if [ "${newline}" != "${oldline[k]}" ] ; then
      tput cup $k 0; tput el; print -nR "${newline}" | cut -c 1-${cols}
      oldline[k]="${newline}"
    fi
  done
  sleep $secs
done

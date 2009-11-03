#!/bin/bash 

#find /data/Vault/ARCS/projects/IMOS/staging/ACORN -daystart -type f \( -mtime 0 -or -mtime 1 \) > fileList

usage() 
{ 
  echo "Usage: `basename $0` -f fileName" 
  exit 1 
} 

if [ $# -ne 2 ]  
then 
    usage 
fi 
while getopts f OPTION 
do 
    case $OPTION in 
    \?) usage 
       ;; 
    esac 
done 


while read line 
do 
   fileCopy=`echo $line|sed 's/staging/opendap/g'`
   if ! [ -f $fileCopy ] || [ -n "`ls $line 2>/dev/null`" ]; then
      echo $line
   fi
done < "$2"


#!/bin/sh

usage() 
{ 
   echo "Usage: `basename $0` -start 2009-07-02 -end 2010-02-03" 
   exit 1 
} 

if [ $# -ne 4 ]; then  
    usage  
fi  

while getopts h:start:end OPTION 
do 
    case $OPTION in 
    h)  usage
        ;;
    \?) usage 
        ;; 
    esac 
done 

startDate=$2
startMonth=`echo $startDate|cut -d'-' -f2`
startYear=`echo $startDate|cut -d'-' -f1`
endDate=$4
endMonth=`echo $endDate|cut -d'-' -f2`
endYear=`echo $endDate|cut -d'-' -f1`

if  [ $startDate \> $endDate ]; then 
     echo "The end datae should be larger than the start date!"
     exit 1
fi

for creation_date in `yes| iquest "SELECT USER_NAME, USER_CREATE_TIME WHERE USER_TYPE  = 'rodsuser'" | grep USER_CREATE_TIME |cut -d'=' -f2`
do
   dateArray=( "${dateArray[@]}" `iadmin ctime $creation_date|cut -d':' -f2|cut -d'.' -f1 | sed -e 's/^[ ]*//'` )
done

exchange()
{
  local temp=${dateArray[$1]} 
  dateArray[$1]=${dateArray[$2]}
  dateArray[$2]=$temp  
  return
}  

number_of_elements=${#dateArray[@]}
let "comparisons = $number_of_elements - 1"
count=1    
while [ "$comparisons" -gt 0 ]        
do                  
  index=0 
  while [ "$index" -lt "$comparisons" ] 
  do
    if [ ${dateArray[$index]} \> ${dateArray[`expr $index + 1`]} ]
    then
        exchange $index `expr $index + 1` 
    fi          
    let "index += 1" 
  done 
let "comparisons -= 1" 
let "count += 1"                
done               

i=0
number=0
temp01=${dateArray[$i]}
while [ $i -le ${#dateArray[*]} ]
do
        if [ "${dateArray[$i]}" = "$temp01" ]; then
           number=`expr $number + 1`
        else
           numUsers=( "${numUsers[@]}" "$number" )
           dateArray01=( "${dateArray01[@]}" "$temp01" )
           number=0
           number=`expr $number + 1`
           temp01=${dateArray[$i]}
        fi
        i=`expr $i + 1`
done

k=0
sub=0
while [ $k -lt ${#dateArray01[*]} ]
do
   if  [ $startDate \> ${dateArray01[$k]} ]; then
       sub=`expr $sub + ${numUsers[$k]}`
   else
       dateArray02=( "${dateArray02[@]}" "${dateArray01[$k]}" )
       numUsers01=( "${numUsers01[@]}" "${numUsers[$k]}" )
   fi
   k=`expr $k + 1`
done

while [ $startDate \< $endDate ]
do
   d=1
   curDays=`cal $startMonth $startYear | grep . | fmt -1 | tail -1`
   while [ $d -le $curDays ]
   do
      dLen=`expr length $d`
      if [ $dLen -lt 2 ]; then
          d="0$d"
      fi
      ymd=`echo "$startYear-$startMonth-"$d`
      allDates=( "${allDates[@]}" "$ymd" )
      if [ "$ymd" = "$endDate" ]; then
          d=`expr $curDays + 1`
      else
          d=`expr $d + 1`
      fi
   done
   if [ $startMonth -eq  12 ]; then 
       startMonth=1
       startYear=`expr $startYear + 1`
   else
       startMonth=`expr $startMonth + 1`
   fi
   monLen=`expr length $startMonth`
   if [ $monLen -lt 2 ]; then
      startMonth="0$startMonth"
   fi
   startDate=$ymd
done

k=0
w=0
echo "Date       " "The number of users"
while [ $k -lt ${#allDates[*]} ]
do
   if [ ${dateArray02[$w]} \> ${allDates[$k]} ]; then
        echo ${allDates[$k]}  " "  $sub
   else
        sub=`expr $sub + ${numUsers01[$w]}`
        echo ${allDates[$k]}  " "  $sub 
        w=`expr $w + 1`
        if [ $w -ge ${#dateArray02[*]} ]; then
            numUsers01=( "${numUsers01[@]}" "0" )
            w=`expr $w - 1`
            dateArray02=( "${dateArray02[@]}" "${dateArray02[$w]}" )
            w=`expr $w + 1`     
        fi      
   fi
   k=`expr $k + 1`
done


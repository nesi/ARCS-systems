#!/bin/sh

function usage()
{
  echo "Usage: $0 -o                 Output encrypted password"
  echo "       $0 -u password_file   Update password from file"
}

SQL="select data_id, path_name from mdas_ad_repl where data_id >=100"
COUNT=0
for i in `psql -U srb MCAT -F " " -A -t -c "$SQL"`
do
  CURRENT=`expr $COUNT "%" 2`
#        echo $item
#        echo $CURRENT
  if [ $CURRENT = 0 ]; then
    DATA_ID=$i
  elif [ $CURRENT = 1 ]; then
    PATH_NAME=$i
    if [ ! -f $i ]; then
      echo "-- $PATH_NAME"
      echo "delete from mdas_ad_repl where data_id = $DATA_ID"
    fi
  fi
  COUNT=`expr $COUNT + 1`
done

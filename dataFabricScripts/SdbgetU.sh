#!/bin/sh
SQL=""
COMPACT=""
#echo $1
#echo $#
if [ $# -gt 0 ]; then
  if [ $1 == "-f" ]; then
    SQL="select mdas_cd_user.*, mdas_td_user_typ.user_typ_name from mdas_cd_user, mdas_td_user_typ where mdas_cd_user.user_typ_id=mdas_td_user_typ.user_typ_id and ( mdas_cd_user.user_typ_id like '0001.0001.0001.0001.000%' or mdas_cd_user.user_typ_id = '0002') and mdas_cd_user.user_id>=100"
  elif [ $1 = "-c" ]; then 
    COMPACT="-t"
    SQL="select user_name from mdas_cd_user where ( mdas_cd_user.user_typ_id like '0001.0001.0001.0001.000%' or mdas_cd_user.user_typ_id = '0002') and mdas_cd_user.user_id>=100"
  fi
  if [ $# -gt 2 ]; then 
    if [ -n $2 -a $2 = "-z" ]; then
      SQL="$SQL and zone_id='$3'"
    fi
  fi
else
  echo "Usage: $0 -f [-z zone_name]     display detailed user information"
  echo "       $0 -c [-z zone_name]     display only usernames"
fi
#echo $SQL

psql -U srb MCAT $COMPACT -c "$SQL"


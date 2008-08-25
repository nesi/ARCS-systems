#!/bin/sh

function usage()
{
  echo "Usage: $0 -o                 Output encrypted password"
  echo "       $0 -u password_file   Update password from file"
}

if [ $# -gt 0 ]; then
  if [ $1 = "-o" ]; then
    SQL="select user_name, zone_id, priv_key from mdas_cd_user, mdas_au_auth_key where mdas_cd_user.user_id=mdas_au_auth_key.user_id and zone_id in (select zone_id from mdas_td_zone where local_zone_flag=1) and mdas_cd_user.user_id>101 and user_name not in (select zone_id from mdas_td_zone) order by mdas_cd_user.user_id"
    psql -U srb MCAT -F " " -A -t -c "$SQL"
  elif [ $1 = "-u" ]; then
    if [ $# -lt 2 ]; then
      usage
    else
      COUNT=0
      for item in `cat $2`; do
        CURRENT=`expr $COUNT "%" 3`
#        echo $item
#        echo $CURRENT
        if [ $CURRENT = 0 ]; then
          USERNAME=$item
        elif [ $CURRENT = 1 ]; then
          ZONE=$item
        elif [ $CURRENT = 2 ]; then
          SQL="update mdas_au_auth_key set priv_key='$item' where user_id in (select user_id from mdas_cd_user where zone_id='$ZONE' and user_name='$USERNAME')"
          echo $SQL
          psql -U srb MCAT -c "$SQL"
        fi
        COUNT=`expr $COUNT + 1`
      done
    fi
  fi
else
  usage
fi

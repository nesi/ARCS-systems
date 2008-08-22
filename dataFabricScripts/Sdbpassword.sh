#!/bin/sh

if [ $# -gt 0 ]; then
  if [ $1 = "-o" ]; then
    SQL="select user_name, priv_key from mdas_cd_user, mdas_au_auth_key where mdas_cd_user.user_id=mdas_au_auth_key.user_id order by mdas_cd_user.user_id"
    psql -U srb MCAT -t -c "$SQL"
  fi
else
  echo "Usage: $0 -o                 Output encrypted password"
  echo "       $0 -u password_file   Update password from file"
fi

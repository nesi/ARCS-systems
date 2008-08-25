#!/bin/sh

execute_sql()
{
  echo $1
  psql -U srb MCAT -c "$1"
}

if [ $# -gt 2 ]; then
#check input 

#update zone_id
  SQL="update mdas_cd_user set zone_id='$3' where user_name = '$1'"
  execute_sql "$SQL"
#Update domain_id in table mdas_au_domn for users of source zone
  SQL="update mdas_au_domn set domain_id=(select domain_id from mdas_td_domn where domain_desc='$3') where user_id in (select user_id from mdas_cd_user where user_name='$1')"
  execute_sql "$SQL"
#Update table mdas_td_data_grp to change collection name to new domain name
  SQL="update mdas_td_data_grp set data_grp_name=replace(data_grp_name,'$2','$3') where data_grp_name like '%$1%'"
  execute_sql "$SQL"
#Update table mdas_au_group to change group to new group name(same as domain name)
  SQL="update mdas_au_group set group_user_id = (select user_id from mdas_cd_user where user_name='$3') where user_id in (select user_id from mdas_cd_user where user_name='$1') and group_user_id in (select user_id from mdas_cd_user where user_name='$2')"
  execute_sql "$SQL"
else
  echo "Usage: $0 [username] [current domain name] [future domain name]"
fi


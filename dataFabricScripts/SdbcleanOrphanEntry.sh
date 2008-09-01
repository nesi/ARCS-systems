#!/bin/sh

function usage()
{
  echo "Usage: $0 [-r resource_name] Print SQL statements to delete orphan entries in database (for a particular PHYSICAL resource)"
}


if [ $# -gt 0 ]; then
  if [ $1 = "-r" ]; then
    SQL="select data_id, path_name, data_grp_name||'/'||data_name from mdas_ad_repl,mdas_td_data_grp,mdas_cd_rsrc where mdas_ad_repl.data_grp_id=mdas_td_data_grp.data_grp_id and mdas_cd_rsrc.rsrc_id=mdas_ad_repl.rsrc_id and data_id >=100 and mdas_cd_rsrc.rsrc_id>=100 and rsrc_typ_id='0001.0001.0001.0001.0003.0001' and rsrc_name like '$2'"
  elif [ $1 = "-h" ]; then
    usage
    exit
  else
    SQL="select data_id, path_name, data_grp_name||'/'||data_name from mdas_ad_repl,mdas_td_data_grp where mdas_ad_repl.data_grp_id=mdas_td_data_grp.data_grp_id and data_id >=100"
  fi
fi
psql -U srb MCAT -F " " -A -t -c "$SQL" | awk '{if (getline< $2<0) {print "--",$2; printf ("--"); for (i=3; i<=NF; i++) { printf("%s ", $i)}; printf("\n"); print "delete from mdas_ad_repl where data_id =",$1,";";}}END {}'

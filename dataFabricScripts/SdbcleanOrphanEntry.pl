#!/usr/bin/perl

if ($ARGV[0] eq "-h"){
  print "Usage: $0 [-r resource_name] Print SQL statements to delete orphan entries in database (for a particular PHYSICAL resource)\n";
  exit();
}
my $sql;
if ($ARGV[1] eq "-r"){
  $sql="select data_id, path_name, data_grp_name||'/'||data_name from mdas_ad_repl,mdas_td_data_grp,mdas_cd_rsrc where mdas_ad_repl.data_grp_id=mdas_td_data_grp.data_grp_id and mdas_cd_rsrc.rsrc_id=mdas_ad_repl.rsrc_id and data_id >=100 and mdas_cd_rsrc.rsrc_id>=100 and rsrc_typ_id='0001.0001.0001.0001.0003.0001' and rsrc_name like '$2'";
}else{
  $sql="select data_id, path_name, data_grp_name||'/'||data_name from mdas_ad_repl,mdas_td_data_grp where mdas_ad_repl.data_grp_id=mdas_td_data_grp.data_grp_id and data_id >=100";
}
my @fields;
my $line;
#$cmd="psql -U srb MCAT -F \" \" -A -t -c \"$sql\"";
#print "querying $cmd\n";
open (HANDLE,"psql -U srb MCAT -F \" \" -A -t -c \"$sql\"|");
#print HANDLE;
while (<HANDLE>){
  chomp($_);
  @fields = split(/ /);
#  print "$fields[1]\n";
#  print "--";
#  foreach $i (2 .. $#fields) {
#    print "$fields[$i] ";
#  }
#  print "\n";
  if (not -e $fields[1]){
    print "--$fields[1]\n";
    print "--";
    foreach $i (2 .. $#fields) {
      print "$fields[$i] ";
    }
    print "\n";
    print "delete from mdas_ad_repl where data_id=$fields[0];\n";
  }
}
close (HANDLE);


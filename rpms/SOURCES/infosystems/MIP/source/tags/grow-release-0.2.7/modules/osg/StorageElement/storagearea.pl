#!/usr/bin/perl -w
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my ($uid,$configdir)=($ARGV[1],$ARGV[2]);

my (%config,$osg_attrib,$vo_map,$user_vo);
my (@output,$appdir,@ret,%vo_list,$user_tmp,$blank);

%config=do "$configdir/osg-conf.pl";
$osg_attrib="$config{vdt_location}/$config{osg_attrib}";
$vo_map="$config{vdt_location}/$config{vo_map}";

exit 1 if not -e "$osg_attrib";

@output=`. $osg_attrib; echo \$OSG_DATA`;
chomp($output[0]);
$appdir=$output[0];
		
exit 2 if not -e "$appdir";

@ret=`df -P -k '$appdir'`;
@ret=split(/\n/,"@ret");
@ret=split(/ +/,"$ret[1]");

open(VOFILE,"<$vo_map") or die "vo_map not found";
while (<VOFILE>){
	if (! (m/^\#/ || m/^\s*$/)) {
		chomp;
		($blank,$user_vo)=split /\ /;
		($blank,$user_vo)=$user_vo =~ /(us)?(\w+)/;
		$vo_list{$user_vo}='';
	}
}

foreach my $vo (keys %vo_list) {
	print "<StorageArea LocalID=\"$vo\">\n";
	print "  <Path>$appdir</Path>\n";
	print "  <Type>permanent</Type>\n";
	print "  <UsedSpace>$ret[3]</UsedSpace>\n" if $ret[3];
	print "  <AvailableSpace>$ret[4]</AvailableSpace>\n" if $ret[4];
	print "  <ACL>\n    <Rule>$vo</Rule>\n  </ACL>\n";
	print "</StorageArea>\n";
}


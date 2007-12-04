#!/usr/bin/perl -w
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my ($uid,$configdir)=($ARGV[1],$ARGV[2]);

my (%config,$grid3_loc,$osg_attrib,@output,$appdir,@array,$tmp);

%config=do "$configdir/osg-conf.pl";
$grid3_loc="$config{grid3_locations}";
$osg_attrib="$config{vdt_location}/$config{osg_attrib}";

exit 1 if not -e "$osg_attrib";

@output=`. $osg_attrib; echo \$OSG_APP`;
chomp($output[0]);
$appdir=$output[0];
$grid3_loc="$appdir/$grid3_loc";	

(@array,$tmp)=((),'');

open(FILE,"<$grid3_loc") or die "grid3_loc not found";
while (<FILE>){
	if(!(m/^\#/ || m/^\s*$/)) {
		chomp;
		push @array,$_;
	}
}

if(@array) {
	print "<RunTimeEnv>\n";
	foreach my $app (@array) {
		print "  <Variable>$app</Variable>\n";
	}
	print "</RunTimeEnv>\n";
}


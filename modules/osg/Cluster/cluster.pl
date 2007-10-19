#!/usr/bin/perl
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config= do "$ARGV[2]/osg-conf.pl";
my $osg_attrib="$config{vdt_location}/$config{osg_attrib}";

if (-e "$osg_attrib") {
	my @output=`. $osg_attrib; echo \$OSG_WN_TMP; echo \$GRID3_TMP_DIR; echo \$HOSTNAME`;
	chomp(@output);

	print "<WNTmpDir>$output[0]</WNTmpDir>\n" if $output[0];
	print "<TmpDir>$output[1]</TmpDir>\n" if $output[1];
	print "<Name>$output[2]</Name>\n" if $output[2];
}

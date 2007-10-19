#!/usr/bin/perl
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config=do "$ARGV[2]/osg-conf.pl";
my $osg_attrib="$config{vdt_location}/$config{osg_attrib}";

my @output=`. $osg_attrib; echo \$OSG_CONTACT_EMAIL; echo \$OSG_SITE_LATITUDE; echo \$OSG_SITE_LONGITUDE; echo \$OSG_SITE_CITY; echo \$OSG_SITE_COUNTRY; echo \$OSG_SPONSOR; echo \$OSG_SITE_NAME; echo \$OSG_SITE_INFO`;

chomp(@output);

if($output[0]) {
	print "<SysAdminContact>mailto: $output[0]</SysAdminContact>\n";
	print "<UserSupportContact>mailto: $output[0]</UserSupportContact>\n";
	print "<SecurityContact>mailto: $output[0]</SecurityContact>\n";
}
print "<Latitude>$output[1]</Latitude>\n"						if $output[1];
print "<Longitude>$output[2]</Longitude>\n"					if $output[2];
print "<Location>$output[3],$output[4]</Location>\n"		if $output[3];
print "<Sponsor>$output[5]</Sponsor>\n"						if $output[5];
print "<Name>$output[6]</Name>\n"								if $output[6];
print "<OtherInfo>$output[7]</OtherInfo>\n" 					if $output[7];

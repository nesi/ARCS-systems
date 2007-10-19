#!/usr/bin/perl
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config= do "$ARGV[2]/osg-conf.pl";

my ($vdt_location,$gatekeeper_conf,$vdt_version,$osg_attrib);

$vdt_location=$config{vdt_location};
$gatekeeper_conf="$vdt_location/$config{gatekeeper_conf}";
$vdt_version="$vdt_location/$config{vdt_version}";
$osg_attrib="$vdt_location/$config{osg_attrib}";

if( -e "$osg_attrib") {
	my @output=`. $osg_attrib; echo \$OSG_APP; echo \$OSG_DATA; echo \$OSG_UTIL_CONTACT; echo \$HOSTNAME`;
	chomp(@output);

	print "<ApplicationDir>$output[0]</ApplicationDir>\n" 					if $output[0];
	print "<DataDir>$output[1]</DataDir>\n"										if $output[1];
	print "<ContactString>$output[2]</ContactString>\n"						if $output[2];
	print "<Name>$output[3]</Name>\n<HostName>$output[3]</HostName>\n"	if $output[3];
}

if(-e "$gatekeeper_conf") {
	my $port=`grep \"port\" $gatekeeper_conf | awk \'{print \$2}\'`;
	chomp($port);
	print "<GateKeeperPort>$port</GateKeeperPort>\n" if $port;
}

if(-e "$vdt_version") {
  	my $version=`$vdt_version | grep \"Globus Toolkit, pre web-services, server\" | awk \'{print \$6}\'`;
  	chomp($version);
	print "<GRAMVersion>$version</GRAMVersion>\n" if $version;
}


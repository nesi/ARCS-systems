#!/usr/bin/perl
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config=do "$ARGV[2]/osg-conf.pl";
my ($outbound,$inbound);

if(defined $config{allow_outbound} and defined $config{allow_inbound}) {
	$outbound=$config{allow_outbound};
	$inbound=$config{allow_inbound};
} else {
	my ($hostname,$ipaddr,@privatelist);
	my ($host,$devnull)=("google.com","/dev/null");
	($outbound,$inbound)=('FALSE','TRUE');

	if(!system("ping -q -c 1 $host 2>$devnull >$devnull")) {
		$outbound="TRUE";
	}

	#FIXME: Need to find a better way to determine inbound network
	$ipaddr=`hostname -i` or $inbound='FALSE';

	@privatelist=('10.','127.0.','172.16.','192.168.');
	foreach my $range (@privatelist) {
		$inbound="FALSE" if $ipaddr=~m/^$range/;
	}
}

#print "<NetworkAdapter OutboundIP=\"$outbound\" InboundIP=\"$inbound\"/>\n" if $outbound and $inbound;
print "<NetworkAdapter OutboundIP=\"$outbound\" InboundIP=\"$inbound\"/>\n";



#!/usr/bin/perl -w
use strict;
use FileHandle;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my $configdir="$ARGV[2]";
my %config=do "$configdir/osg-conf.pl";

my $osg_attrib="$config{vdt_location}/$config{osg_attrib}";
my $vo_map="$config{vdt_location}/$config{vo_map}";

exit 1 if not -e "$osg_attrib";

my @output=`. $osg_attrib; echo \$OSG_APP; echo \$OSG_DATA; echo \$OSG_DEFAULT_SE`;
chomp(@output);

print "<ApplicationDir>$output[0]</ApplicationDir>\n"		if $output[0];
print "<DataDir>$output[1]</DataDir>\n"						if $output[1];
print "<DefaultSE>$output[2]</DefaultSE>\n" 					if $output[2];

my (%vo_list,$blank,$user_vo);
open(VOFILE,"<$vo_map") or die "vo_map not found";
while (<VOFILE>){
   if (! (m/^\#/ || m/^\s*$/)) {
      chomp;
      ($blank,$user_vo)=split /\ /;
      $vo_list{$user_vo}='';
   }
}

foreach my $vo (keys %vo_list) {
	print "<VOView LocalID=\"$vo\">\n";
	print "  <ApplicationDir>$output[0]</ApplicationDir>\n"	if $output[0];
	print "  <DataDir>$output[1]</DataDir>\n"						if $output[1];
	print "  <DefaultSE>$output[2]</DefaultSE>\n" 				if $output[2];
	print "</VOView>\n";
}




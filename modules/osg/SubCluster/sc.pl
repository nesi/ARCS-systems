#!/usr/bin/perl
use strict;
use FileHandle;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config= do "$ARGV[2]/osg-conf.pl";
my $osg_attrib="$config{vdt_location}/$config{osg_attrib}";
my $sc_nodes=$config{sc_nodes};

if (-e "$osg_attrib") {
   my @output=`. $osg_attrib; echo \$OSG_WN_TMP; echo \$GRID3_TMP_DIR; echo \$HOSTNAME`;
	chomp(@output);

   print "<WNTmpDir>$output[0]</WNTmpDir>\n" 	if $output[0];
   print "<TmpDir>$output[1]</TmpDir>\n" 			if $output[1];
   print "<Name>$output[2]</Name>\n" 				if $output[2];
}

my ($file,@os);

$file="/proc/cpuinfo";
if (-e $file){
	my ($model,$vendor,$clock,$flags,%physicalid);
	my ($pcpu,$lcpu)=(0,0);
	open(FILE, "<$file");
	while(<FILE>) {
		$model=$1 if /^model\s*name\s*\:\s*(.*)/;
		$vendor=$1 if /^vendor_id\s*\:\s*(.*)/;
		$clock=$1 if /^cpu\s*MHz\s*\:\s*(.*)/;
		$flags=$1 if /^flags\s*\:\s*(.*)/;
		$physicalid{$1}='' if /^physical\s*id\s*\:\s*(.*)/;
		if(/^processor\s*\:\s*(.*)/) {
			$lcpu=$1 if $1 gt $lcpu;
		}
	}

	$pcpu=(keys %physicalid);
	$lcpu=$lcpu+1; # Counting starts at zero in /proc/cpuinfo

	#FIXME: Define PlatformType
   print "<Architecture PlatformType=\"none\" SMPSize=\"$lcpu\" />\n";
	$pcpu=$pcpu*$sc_nodes;
	$lcpu=$lcpu*$sc_nodes;
	$clock=int($clock);
   print "<Processor Model=\"$model\" ClockSpeed=\"$clock\" Vendor=\"$vendor\" " .
      "OtherDescription=\"None\" InstructionSet=\"$flags\"/>\n" .
      "<PhysicalCPUs>$pcpu</PhysicalCPUs>\n" .
      "<LogicalCPUs>$lcpu</LogicalCPUs>\n";
}

$file="/proc/meminfo";
if (-e $file){
	my ($ram,$swap);
	open(FILE, "<$file");
	while(<FILE>) {
		$ram=int($1/1024) if /^MemTotal\s*\:\s*(.*)\s*kB\s*$/;
		$swap=int($1/1024) if /^SwapTotal\s*\:\s*(.*)\s*kB\s*$/;
	}
	$swap=$swap+$ram;
	print "<MainMemory VirtualSize=\"$swap\" RAMSize=\"$ram\"/>\n";
}

$os[0]=`lsb_release -d 2>/dev/null | cut -f2`;
if($os[0]) {
	$os[1]=`lsb_release -s -i`;
	$os[2]=`lsb_release -s -r`;
	chomp(@os);

	# FIXME: Need to include lsb_release exceptions here

	print "<OperatingSystem Name=\"$os[0]\" Release=\"$os[1]\" Version=\"$os[2]\"/>";
}



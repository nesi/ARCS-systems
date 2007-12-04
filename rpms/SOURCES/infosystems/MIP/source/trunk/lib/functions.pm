#!/usr/bin/perl -w
use strict;
use Switch;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

##### HASH FUNCTIONS

sub addhash
{ # function to add a subhash to a larger hash
	my ($hsh,$subhsh)=@_;
	foreach my $subhshel (keys %{$subhsh}) {
		addelement($hsh,$subhshel,$$subhsh{$subhshel});
	}
}

#FIXME: Do not save blank value elements

sub addelement
{	# Ugly function to handle hash-hash collisions nicely
	my ($hsh,$el,$val)=@_;
	($el,$val)=elexceptionhandlerhsh($el,$val) if elexception($el);

	if(exists $$hsh{$el}) { #Collision
		if(ref($$hsh{$el}) eq "HASH") { # Collision with hash
			if(ref($val) eq "HASH") { # Collision with 2 hashes
				foreach my $hshel (keys %$val) { #Add/overwrite each element of new hash with old hash
					addelement($$hsh{$el},$hshel,$$val{$hshel}); # Recurse to add different elements in hash
				}
			}
			# don't do an else, otherwise scalar overwrites hash which shouldn't happen
		} else { # Collision with non-hash, so overwrite
			$hsh->{"$el"}=$val;
		}
	} else { # No-collision, add
		$hsh->{"$el"}=$val;
	}
}

sub elexception 	# Used to handle multiple elements without attributes 
{						# These would normally hash to the same value
	my ($el)=@_;   # Need to add all elements that will have same Attribute for multiple values
	switch ($el) {
		case /^Sponsor/ { return 1; }
		case /^OtherInfo/ { return 1; }
		case /^ContactString/ { return 1; }
		case /^Rule/ { return 1; }
		case /^Capability/ { return 1; }
		case /^Variable/ { return 2; }
		case /^GlueCEAccessControlBaseRule/ { return 3; }
		case /^GlueSAAccessControlBaseRule/ { return 4; }
		case /^RunTimeEnvironment/ { return 5; }
		case /^GlueHostApplicationSoftwareRunTimeEnvironment/ { return 5; }
	}
}

sub elexceptionhandlerhsh
{	# A simply way to handle hash collisions
	my ($el,$val)=@_;
	my $slen=length $val;
	my $subs=substr($el,-$slen);
	return ($el,$val) if $subs eq $val;
	return ("$el $val",$val);
}

sub elexceptionhandlerprint
{	# Reverse the hash collision handler's actions
	my ($el)=@_;
	my @elsplit=split(/ /,$el,2);
	return ($elsplit[0]);
}

sub singleelement
{	# Check if its a single element
	return $_[0]=~m/^\s*<\s*[^>]+?\/>/;
}
sub singleelementparser
{	# Parse single element
	return ($1,$2) if $_[0]=~m/\s*<\s*(.+?)\s*\/>\s*(.*)/;
	return ('','');   # <$1/> $2
}

sub nestedelement
{	# Check if its a nested element
	return $_[0]=~m/^\s*(?<!\>)<[^\/][^\<\>]*?>\s*<[^\/].*?>.*?/;
}

sub nestedelementparser
{	# Parse nested element
	return ($1,$2) if $_[0]=~/\s*<\s*(.+?)\s*>\s*(.+)/;
	return ('','');   # <$1> $2
}

sub canbeparsed
{	# Check if the string contains valid XML
	return 1 if $_[0]=~m/^(\s*<[^\/].+?>.*?<\/.+?>.*?)/;
	return singleelement($_[0]);
}

sub fullelement
{  # Check if its a full element
	return $_[0]=~m/^\s*<(.+)>\s*(.*?)\s*<\/\1>/;
}

sub fullparser
{	# Parse the information
	return ($1,$2,$3) if $_[0]=~/\s*<\s*(.+)\s*>\s*(.*?)\s*<\/\1>\s*(.*)\s*/;
	return ('','','');   # <$1>$2</$1>$3

}

##### XML PARSER

sub xmlparser
{  # Just me, it parses XML
	my ($arr,$loc,$end_element,$hsh)=@_;
	my ($maxloc,$str,$element,$attr,$val,$tmp,);
	$maxloc=@{$arr};
	$str='';
	while($$loc<$maxloc) {
		$tmp=$$arr[$$loc];
		chomp($tmp);
		$tmp=$1 if $tmp=~/\s*(.+)\s*/; # FIXME: to just tmp=regex
		$str="$str $tmp";
		if($end_element ne '' and $str=~m/^\s*$end_element\s*(.*)\s*/) {
			$$arr[$$loc]=$1;  #Save the rest to be parsed
			return 0;         #Exit out of sub
		}
		while(canbeparsed($str)) {
			if(singleelement($str)) {
				($element,$str)=singleelementparser($str);
				addelement($hsh,$element,'');
			} 
			elsif(fullelement($str)) {
				($element,$val,$str)=fullparser($str);
				if(canbeparsed($val)) {
					my (%nestedhsh,$zeroloc,@tmparr)=((),0,($val));
					xmlparser(\@tmparr,\$zeroloc,'',\%nestedhsh); # end element already parsed out
					$val=\%nestedhsh;
				}
				addelement($hsh,$element,$val);
			} 
			elsif(nestedelement($str)) {
				($element,$str)=nestedelementparser($str);
				my $endelement=endelement($element);
				my %nestedhsh;
				chomp($endelement); 
				$$arr[$$loc]=$str;
				xmlparser($arr,$loc,$endelement,\%nestedhsh);
				addelement($hsh,$element,\%nestedhsh);
				$str=$$arr[$$loc] or $str=''; 
			} 
		}

		$$loc++;
	}
}

##### XML PROCESSORS

sub fastprocessor
{	# Process XML quickly
	my ($hsh)=@_;
	my ($el,$ptr,@hshlist);
	foreach $el (keys %$hsh) {
		$ptr=$$hsh{$el};
		if(ref($ptr) eq "HASH") {
			print startelement("$el");
			fastprocessor($ptr);	
			print endelement("$el");	
		} else {
			print element($el,$ptr);
		}
	}
}

sub debugprocessor
{	# Process XML, but sort elements and make it easier for human consumption
	my ($hsh,$space)=@_;
	my ($el,$ptr,@hshlist);
	foreach $el (sort (keys %$hsh)) {
		$ptr=$$hsh{$el};
		if(ref($ptr) eq "HASH") {
			push(@hshlist,"$el");
		} else {
			print spaces($space).element($el,$ptr);
		}
	}
	foreach my $el (@hshlist) {
		print spaces($space).startelement("$el");
		debugprocessor($$hsh{$el},$space+2);
		print spaces($space).endelement("$el");
	}
}

sub sortprocessor
{	# Process XML, but sort elements and make it easier for human consumption
	my ($hsh,$space,$parent)=@_;
	my ($el,$ptr,@hshlist,$orderel,@hshkeys);
	@hshkeys=sort(keys (%$hsh));
	foreach $orderel (getorder($parent)) {
		foreach $el (@hshkeys) {
			if($el=~m/^$orderel/ or $orderel eq 'MIPALL') {
				next if $el=~m/^$orderel\w+/;
				$ptr=$$hsh{$el};
				if(ref($ptr) eq "HASH") {
					print spaces($space).startelement("$el");
					my @beginel=split(/ /,$el);
					sortprocessor($$hsh{$el},$space+2,$beginel[0]);
					print spaces($space).endelement("$el");
				} else {
					print spaces($space).element($el,$ptr);
				}
			}
		}
	}
}

sub getorder
{
	my ($parent)=@_;
	my @arr;
	switch ($parent) {
		case /^ACL/ { @arr=('Rule'); }
		case /^RunTimeEnv/ { @arr=('Variable'); }
		case /^Job/ { @arr=('GlobalID','LocalOwner','GlobalOwner','Status','SchedulerSpecific'); }
		case /^AccessProtocol/ { @arr=('Endpoint','Type','Version','Capability'); }
		case /^ControlProtocol/ { @arr=('Endpoint','Type','Version','Capability'); }
		case /^VOView/ { @arr=('ACL','RunningJobs','WaitingJobs','TotalJobs','FreeJobSlots','EstimatedResponseTime','WorstResponseTime','DefaultSE',
										'ApplicationDir','DataDir'); }
		case /^ComputingElement/ { @arr=('InformationServiceURL','Name','LRMSType','LRMSVersion','GRAMVersion','HostName','GateKeeperPort','JobManager','ContactString',
											'ApplicationDir','DataDir','DefaultSE','Status','RunningJobs','WaitingJobs','TotalJobs','EstimatedResponseTime','WorstResponseTime',
											'FreeJobSlots','MaxWallClockTime','MaxCPUTime','MaxTotalJobs','MaxRunningJobs','Priority','AssignedJobSlots','ACL','Job','VOView'); }
		case /^SoftwarePackage/ {  @arr=('Name','Version','Path','QueueResource','Module','SerialAvail','ParallelAvail','ParallelMaxCPUs','SoftwareExecutable'); }
		case /^SoftwareExecutable/ {  @arr=('Name','Version','Path','SerialAvail','ParallelAvail','ParallelMaxCPUs'); }
		case /^SubCluster/ { @arr=('Name','PhysicalCPUs','LogicalCPUs','TmpDir','WNTmpDir','OperatingSystem','Processor','NetworkAdapter','MainMemory','Architecture',
									'Benchmark','Location','RunTimeEnv','SoftwarePackage'); }
		case /^StorageArea/ { @arr=('Path','Type','Quota','MinFileSize','MaxFileSize','MaxData','MaxNumFiles','MaxPinDuration','UsedSpace','AvailableSpace','ACL'); }
		case /^Cluster/ { @arr=('Name','TmpDir','WNTmpDir','ComputingElement','SubCluster'); }
		case /^Service/ { @arr=('Name','Type','Version','Endpoint','Status','StatusInfo','WSDL','Semantics','StartTime','Owner','Data'); }
		case /^StorageElement/ { @arr=('Name','InformationServiceURL','SizeTotal','SizeFree','Architecture','StorageArea','AccessProtocol','ControlProtocol'); }
		case /^Host/ { @arr=('Name','UpTime','Architecture','MainMemory','OperatingSystem','Processor','Load','NetworkAdapter','Benchmark','RunTimeEnv','StorageDevice',
									'StoragePartition','LocalFileSystem','RemoteFileSystem','StorageDevice2StoragePartition','StoragePartition2FileSystem'); }
		case /^Site/ { @arr=('Name','Description','UserSupportContact','SysAdminContact','SecurityContact','Location','Latitude','Longitude','Web','Sponsor','OtherInfo',
									'Cluster','StorageElement','Service','CESEBind','Service2Service','Host'); }
		else { @arr=('MIPALL'); }
	}	
	return @arr;
}

sub processor
{
	my ($hsh)=@_;
#	fastprocessor($hsh);
#	debugprocessor($hsh,2);
	sortprocessor($hsh,2,'');
}

1;

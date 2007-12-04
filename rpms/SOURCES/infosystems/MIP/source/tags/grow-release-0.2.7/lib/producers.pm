#!/usr/bin/perl -w
use strict;
use Switch;
use lib::functions;


# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

#	$hsh={	GlueForeignKey => [ 'fk1','fk2', ],
#				GlueChunkKey => 	[ 'ck1','ck2', ],
#				objectClass => 	[ 'oc1','oc2', ],
#				Records => {
#									attr1 => 'val1',
#									attr2 => 'val2',
#								},
#				glueSchemaMajor => '1',
#				glueSchemaMinor => '2',
#				glueInformationServiceURL => 'http://service.url.com',
#			};
#	$hsh={ DN1 => $hsh, DN2 => $hsh };

# FIXME: Need to include key names in the dn

# FIXME: Remove below
use Data::Dumper;

sub ldapclass
{			
	my ($parent,$name)=@_;
	my ($objects,$el,$aname,$objectclass);
	$objectclass='';
	$objects={ 	
		Site => { GlueSite => ['Name','Description','UserSupportContact','SysAdminContact','SecurityContact','Location','Latitude','Longitude','Web','Sponsor',
										'OtherInfo','UniqueID',],
				  },
		Cluster => 	{ GlueCluster => ['Name','UniqueID', ],	
						},
		SubCluster => 	{
							GlueHostApplicationSoftware => ['RunTimeEnvironment',],
							GlueHostArchitecture => ['SMPSize','PlatformType',],
							GlueHostBenchmark => ['SF00','SI00',],
							GlueHostMainMemory => ['RAMSize','VirtualSize',],
							GlueHostNetworkAdapter => ['InboundIP','OutboundIP',],
							GlueHostOperatingSystem => ['OSName','Release','Version',], # OSName hack for collision
							GlueHostProcessor => ['ClockSpeed','Model','Vendor','InstructionSet','OtherProcessorDescription',],
							GlueSubCluster => ['Name','UniqueID','PhysicalCPUs','LogicalCPUs','TmpDir','WNTmpDir',],
							},
		ComputingElement => 	{
									GlueCEAccessControlBase => ['Rule',],
									GlueCEInfo => ['GatekeeperPort','HostName','LRMSType','LRMSVersion','TotalCPUs','JobManager',
														'ContactString','ApplicationDir','DataDir','DefaultSE','GRAMVersion',],
									GlueCEPolicy => ['MaxCPUTime','MaxRunningJobs','MaxTotalJobs','MaxWallClockTime','Priority','AssignedJobSlots',],
									GlueCEState => ['EstimatedResponseTime','FreeCPUs','RunningJobs','Status','TotalJobs','WaitingJobs','WorstResponseTime','FreeJobSlots',],
									GlueCE => ['UniqueID','Name',],
									},
		StorageElement => 	{
									GlueSE => ['UniqueID','Name','Port','SizeTotal','SizeFree','Architecture','Type',],
									},
		StorageArea =>			{
									GlueSA => ['Root','LocalID','Path','Type','UniqueID',],
									GlueSAPolicy => ['MaxFileSize','MinFileSize','MaxData','MaxNumFiles','MaxPinDuration','Quota','FileLifeTime',],
									GlueSAState => ['AvailableSpace','UsedSpace',],
									GlueSAAccessControlBase => ['Rule',],
									},
		VOView =>	{
						GlueCEAccessControlBase => ['Rule',],
						GlueCEInfo => ['DefaultSE','ApplicationDir','DataDir',],
						GlueCEState => ['RunningJobs','TotalJobs','WaitingJobs','FreeJobSlots',],
						GlueVOView  => ['LocalID',],
						},
		CESEBind => {
						GlueCESEBindGroup => ['CEUniqueID','SEUniqueID',],
						GlueCESEBind => ['CEUniqueID','CEAccesspoint','SEUniqueID','MountInfo','Weight',],
						},
	};
	$name=elexceptionhandlerprint($name) if elexception($name);
	foreach $el (keys %{$$objects{$parent}}) {
		foreach $aname (@{$$objects{$parent}{$el}}) {
			$objectclass=$el if $name eq $aname;
		}
	}
	return $objectclass;	
}

sub processorldap
{
	my ($hsh)=@_;
	my ($el,$dn,$ptr,$ref,$rec,%unique,$tmp,$odn);
	my @order=('Site','CE','VOView','Cluster','SubCluster','Location','CESEBind','SE','SA',);

	foreach $odn (@order) {
		foreach $dn (sort keys %$hsh) {
			if($dn=~/^Glue$odn/) {
				print "dn: $dn, mds-vo-name=local,o=grid\n";
				foreach $el (reverse sort keys %{$$hsh{$dn}}) {
					$ptr=$$hsh{$dn}{$el};
					if($ref=ref($ptr)) {
						if($ref eq "HASH") { # Records
							foreach $rec (keys %$ptr) {
								$tmp=$$ptr{$rec};
								$rec=elexceptionhandlerprint($rec) if elexception($rec);
								#print "$rec: $tmp\n" if $tmp and $tmp ne '';
								print "$rec: $tmp\n";
							}
						} 
						elsif($ref eq "ARRAY") { # Keys and Classes
							%unique=map {$_=>1} @{$ptr};
							foreach $rec (keys %unique) {
								print "$el: $rec\n";
							}
						}
					} else { # Schema and URL
						print "$el: $ptr\n";
					}
				}
				print "\n";
			}
		}
	}
}

sub addrecord
{
	my ($ldap,$hsh,$parent)=@_;
	my ($iel,$class,$ptr);
	foreach $iel (keys %$hsh) {
		$ptr=$$hsh{$iel};
		if(ref($ptr) ne "HASH") {
			$class=ldapclass($parent,$iel);
			if($class ne '') {
				$iel="Name" if "$class$iel" eq "GlueHostOperatingSystemOSName"; 
				$$ldap{Records}{"$class$iel"}=$ptr;
				push(@{$$ldap{objectClass}},$class);
			}
		}
	}
	return $ldap;
}

sub producerglueldapnext
{
	my ($ldap,$hsh,$parentuid)=@_;
	my ($el,$iel,$class,$rec,$chel);
	foreach $el (keys %$hsh) {
		$rec='';
		if($el=~/^Site/) {
			$chel="GlueSiteUniqueID=".$$hsh{$el}{Name};
			push(@{$$ldap{$chel}{objectClass}},'GlueTop');
			$$hsh{$el}{UniqueID}=$$hsh{$el}{Name};
			$rec='Site';
		}
		elsif($el=~/^Cluster/) {
			$chel="GlueClusterUniqueID=".$$hsh{$el}{Name};
			push(@{$$ldap{$chel}{objectClass}},'GlueClusterTop');
			push(@{$$ldap{$chel}{objectClass}},'GlueInformationService');
			$$hsh{$el}{UniqueID}=$$hsh{$el}{Name};
			#FIXME: Need CE children for ForeignKey links
			$rec='Cluster';
		}
		elsif($el=~/^SubCluster/) {
			#FIXME: Needs the parent
			$chel="GlueSubClusterUniqueID=".$$hsh{$el}{Name}.", ".$parentuid;
			push(@{$$ldap{$chel}{objectClass}},'GlueClusterTop');
			$$hsh{$el}{UniqueID}=$$hsh{$el}{Name};
			$rec='SubCluster';
		}
		elsif($el=~/^ComputingElement/) {
			$$hsh{$el}{GateKeeperPort}=2119 if not $$hsh{$el}{GateKeeperPort}; # Hardcoded element
			my $uid=$$hsh{$el}{HostName}.":".$$hsh{$el}{GateKeeperPort}."/".$$hsh{$el}{JobManager};
			$chel="GlueCEUniqueID=".$uid;
			push(@{$$ldap{$chel}{objectClass}},'GlueCETop');
			push(@{$$ldap{$chel}{GlueForeignKey}},$parentuid);
			push(@{$$ldap{$chel}{objectClass}},'GlueKey');
			$$hsh{$el}{UniqueID}=$uid;
			$rec='ComputingElement';
		}
		elsif($el=~/^VOView/) {
			my @splitstr=split(/"/,$el);
			$chel="GlueVOViewLocalID=".$splitstr[1].",".$parentuid;
			push(@{$$ldap{$chel}{objectClass}},'GlueVOView');
			$$hsh{$el}{LocalID}=$splitstr[1];
			$rec='VOView';
		}
		elsif($el=~/^Location/) {
			my @splitstr=split(/"/,$el);
			$chel="GlueLocationLocalID=".$splitstr[1].",".$parentuid;
			push(@{$$ldap{$chel}{objectClass}},'GlueLocation');
			$$hsh{$el}{LocalID}=$$hsh{$el}{Name};
			$rec='Location';
		}
		elsif($el=~/^StorageElement/) {
			my @splitstr=split(/"/,$el);
			$chel="GlueSEUniqueID=".$splitstr[1];
			push(@{$$ldap{$chel}{objectClass}},'GlueSETop');
			$$hsh{$el}{UniqueID}=$splitstr[1];
			$rec='StorageElement';
		}
		elsif($el=~/^StorageArea/) {
			my @splitstr=split(/"/,$el);
			$chel="GlueSALocalID=".$splitstr[1].",".$parentuid;
			push(@{$$ldap{$chel}{objectClass}},'GlueSATop');
			$$hsh{$el}{LocalID}=$splitstr[1];
			$rec='StorageArea';
		}
=pod
		elsif($el=~/^CESEBind/) {
#FIXME: Need to build everything here
#Need to build everything in here, because everything comes from the attributes
			if($el=~/^CESEBind CEUniqueID=\"(.+)?\" SEUniqueID=\"(.+)?\" MountInfo=\"(.+)?\" Weight=\"(.+)?\"/) {
				my ($ceuid,$seuid,$mountinfo,$weight)=($1,$2,$3,$4); 
print "c=$ceuid s=$seuid m=$mountinfo w=$weight\n";
				$chel="GlueCESEBindGroupCEUniqueID=".$ceuid;
#FIXME: below
#Need to turn into a hash somehow
#				$$hsh{$el}{CEUniqueID}=$ceuid;
#				$$hsh{$el}{SEUniqueID}=$seuid;
#				push(@{$$ldap{$chel}{objectClass}},'GlueCESEBindGroup');
				$rec='CESEBind';
			}
		}
=cut
		if($rec ne '') {
			$$ldap{$chel}=addrecord($$ldap{$chel},$$hsh{$el},$rec);
			if($parentuid ne '') {
				push(@{$$ldap{$chel}{GlueChunkKey}},$parentuid); 
				push(@{$$ldap{$chel}{objectClass}},'GlueKey');
			}
			$$ldap{$chel}{GlueSchemaVersionMajor}=1;
			$$ldap{$chel}{GlueSchemaVersionMinor}=2;
			push(@{$$ldap{$chel}{objectClass}},'GlueSchemaVersion');
		}
		if(ref($$hsh{$el}) eq "HASH") {
			$ldap=producerglueldapnext($ldap,$$hsh{$el},$chel);
		}
	}
	return $ldap;
}


sub producerglueldap
{
	my ($inhsh)=@_;
	my (%ldap,$hsh,$el,$iel,$class);
	$hsh=producerglue($inhsh);
	$hsh=producergluealter($hsh);
	$hsh=producerglueldapnext(\%ldap,$hsh,'');
#FIXME: Remove below
print Dumper($hsh);
	return $hsh;
}

sub splitel
{
	my ($el)=@_;
	my ($name,@attrs,$attrstr,$aname,$aval,$blank);
	($name,$attrstr)=split(/ /,$el,2);
	while($attrstr) {
		($aname,$attrstr)=split(/=/,$attrstr,2);
		$aname=~/\s*(.+)/;
		($blank,$aval,$attrstr)=split(/"/,$attrstr,3);
		push(@attrs,"$aname=$aval");
	}

	return ($name,@attrs);
}


sub producergluealter
{
	my ($hsh)=@_;
	my ($el,$ptr,$iel,@attrlist,$attr,$name,@attrs,$iattr,$a,$v);
	foreach $el (keys %$hsh) {
		$ptr=$$hsh{$el};
		if($el=~/^SubCluster/) {
			@attrlist=('OperatingSystem','Processor','NetworkAdapter','MainMemory','Architecture');
			foreach $iel (keys %$ptr) {
				foreach $attr (@attrlist) {
					if($iel=~/^$attr/) {
						($name,@attrs)=splitel($iel);
						foreach $iattr (@attrs) {
							($a,$v)=split(/=/,$iattr);
							$a=~s/\s+//g;
							$a="OtherProcessorDescription" if "$name$a" eq "ProcessorOtherDescription";
							$a="OSName" if "$name$a" eq "OperatingSystemName";
							$$ptr{"$a"}=$v;
						}
					delete($$ptr{$iel});
					}
				}
				if($iel=~/RunTimeEnv/) {
					foreach $attr (keys %{$$ptr{RunTimeEnv}}) {
						addelement($ptr,"RunTimeEnvironment",$$ptr{RunTimeEnv}{$attr}) if $$ptr{RunTimeEnv}{$attr};
					}
					delete($$ptr{RunTimeEnv});
				}
			}
		}
		if($el=~/^ComputingElement/ or $el=~/^VOView/ or $el=~/StorageArea/) {
			foreach $iel (keys %$ptr) {
				if($iel eq 'ACL') {
					foreach $iattr (keys %{$$ptr{$iel}}) {
						$a="Rule $$ptr{$iel}{$iattr}";
						$$ptr{"$a"}=$$ptr{$iel}{$iattr};
					}
					delete($$ptr{$iel});
				}
			}
		}
		if($el=~/^ComputingElement/) {
			foreach $iel (keys %$ptr) {
				if($iel eq 'GateKeeperPort') {
					$$ptr{'GatekeeperPort'}=$$ptr{$iel};
					delete($$ptr{$iel});
				}
			}
		}
		if(ref($$hsh{$el}) eq "HASH") {
			$$hsh{$el}=producergluealter($$hsh{$el});
		}
	}
	return $hsh;
}



sub producerglue
{  # Produce Glue Schema 1.2 XML
	my ($ahsh)=@_;
	my (%hsh,$cluster,$uid,$root);
	my (%clusterhsh,@clusterlist);

	#Get a unique list of cluster names
	foreach $root (keys %$ahsh) {
		%clusterhsh=map{$_=>1} (keys %{$$ahsh{$root}});
	}
	@clusterlist=keys %clusterhsh;
	
	#Put non-root information into correct place in hash (prepare for root information input)
	foreach $root ('ComputingElement','SubCluster') {
		foreach $cluster (keys %{$$ahsh{$root}}) {
			foreach $uid (keys %{$$ahsh{$root}{$cluster}}) {
				if(exists $$ahsh{Cluster}{$cluster}) {
					foreach my $clusteruid (keys %{$$ahsh{Cluster}{$cluster}}) {
						addelement($$ahsh{Cluster}{$cluster}{$clusteruid},"$root UniqueID=\"$uid\"",$$ahsh{$root}{$cluster}{$uid});
					}
				}
			}
		}
	}

	#Output all non-cluster possible-root information
	foreach $root ('StorageElement','Cluster') {
		foreach $cluster (keys %{$$ahsh{$root}}) {
			foreach $uid (keys %{$$ahsh{$root}{$cluster}}) {
				addelement(\%hsh,"$root UniqueID=\"$uid\"",$$ahsh{$root}{$cluster}{$uid});
			}
		}
	}

	#Bind CE's and SE's that share the same cluster together
	foreach $cluster (@clusterlist) {
		foreach my $ce (keys %{$$ahsh{ComputingElement}{$cluster}}) {
			foreach my $se (keys %{$$ahsh{StorageElement}{$cluster}}) {
				addelement(\%hsh,"CESEBind CEUniqueID=\"$ce\" SEUniqueID=\"$se\" MountInfo=\"None\" Weight=\"0\"","");
			}
		}
	}

	#Add Site to hash and return
	my %rethsh;
	foreach $cluster (keys %{$$ahsh{Site}}) {
		foreach $uid (keys %{$$ahsh{Site}{$cluster}}) {
			addhash(\%hsh,$$ahsh{Site}{$cluster}{$uid});
			addelement(\%rethsh,"Site UniqueID=\"$uid\"",\%hsh);
		}
	}
	return \%rethsh;
}

sub producer
{	# produce information in certain schema format
	my ($hsh,$produce)=@_;
	switch($produce) {
		case /^glueldap/ 	{ processorldap(producerglueldap($hsh)); }
		case /^glue/ 		{ sortprocessor(producerglue($hsh),2,''); }
		case /^gluexml/ 	{ sortprocessor(producerglue($hsh),2,''); }
		case /^rawxml/ 	{ debugprocessor($hsh,2); }
		else					{ print "producer does not exist \n"; exit 1; }
	}
}

1;

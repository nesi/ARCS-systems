#!/usr/bin/perl
use strict;
use Sys::Hostname;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my %config=do "$ARGV[2]/osg-conf.pl";

my ($vo_map,$pbs_path,$pbshost,$hostname,$free_cpus,$total_cpus);
my (%queues,%vo_list,$blank,$user_vo,$version,@output,%printq);

$vo_map="$config{vdt_location}/$config{vo_map}";
$pbs_path="$config{pbs_path}";
$pbshost="$config{pbs_host}" or $pbshost='';
$hostname=hostname();

#@output=`$pbs_path/qstat -B -f`;	
@output=`$pbs_path/qstat -B -f 2>/dev/null`;	
foreach (@output) {
	$version=$1 if /pbs_version\s+=\s+(\S+)/;
}

print "<LRMSType>Torque</LRMSType>\n<JobManager>pbs</JobManager>\n";
print "<LRMSVersion>$version</LRMSVersion>\n" 						if $version;
print "<ContactString>$hostname/jobmanager-pbs</ContactString>\n" 	if $hostname;
	
#$blank="$pbs_path/pbsnodes -a";
$blank="$pbs_path/pbsnodes -a";
$blank="$blank -s $pbshost" if $pbshost ne '';

($free_cpus,$total_cpus)=process_pbsnodes("$blank 2>&1");
%queues=process_queues($pbs_path,$hostname);

foreach my $q (keys %queues) {
	foreach my $el (keys %{$queues{$q}}) {
		next if $el eq "ACL"; # Can't add up ACL rules
		if($el eq "MaxWallTime" or $el eq "MaxCPUTime") {
			$printq{$el}=$queues{$q}{$el} if $printq{$el}<$queues{$q}{$el};
		} else {
			$printq{$el}+=$queues{$q}{$el};
		}
	}
	$printq{FreeJobSlots}+=$queues{$q}{MaxTotalJobs}-$queues{$q}{TotalJobs} if defined $queues{$q}{MaxTotalJobs} and defined $queues{$q}{TotalJobs};
}

$printq{MaxRunningJobs}=$total_cpus if defined $total_cpus;
if(defined $free_cpus) {
	$printq{FreeJobSlots}=$free_cpus if not defined $printq{FreeJobSlots} or $printq{FreeJobSlots} > $free_cpus;
}
foreach my $el (keys %printq) {
	print "<$el>$printq{$el}</$el>\n";
}

open(VOFILE,"<$vo_map") or die "vo_map not found";
while (<VOFILE>){
   if (! (m/^\#/ || m/^\s*$/)) {
      chomp;
      ($blank,$user_vo)=split /\ /;
      $vo_list{$user_vo}='';
   }
}

foreach my $vo (keys %vo_list) {
	my %jobs=('WaitingJobs',0,'RunningJobs',0,'TotalJobs',0,'MaxTotalJobs',0,'FreeJobSlots',0);
	foreach my $queue (keys %queues) {
		if($queues{$queue}{ACL}{$vo}) {
			foreach my $el (keys %jobs) {
				$jobs{$el}+=$queues{$queue}{$el} if defined $queues{$queue}{$el};
			}
		}
	}
	$jobs{FreeJobSlots}=$jobs{MaxTotalJobs}-$jobs{TotalJobs} if defined $jobs{MaxTotalJobs} and defined $jobs{TotalJobs};
	if(defined $free_cpus) {
		$jobs{FreeJobSlots}=$free_cpus if not defined $jobs{FreeJobSlots} or $jobs{FreeJobSlots} > $free_cpus;
	}
	print "<VOView LocalID=\"$vo\">\n  <ACL>\n    <Rule>VO:$vo</Rule>\n  </ACL>\n";
	foreach my $el (keys %jobs) {
		print "  <$el>$jobs{$el}</$el>\n" if $el ne "MaxTotalJobs"; # MaxTotalJobs not in VOView schema
	}
	print "</VOView>\n";
}

print "<ACL>\n";
foreach my $vo (keys %vo_list) {
	print "  <Rule>$vo</Rule>\n";
}
print "</ACL>\n";

sub process_pbsnodes 
{	# process information from pbsnodes -a
	my ($pbsnodes)=@_;
	my @output=`$pbsnodes`; 
	my ($total_cpus,$free_cpus,$np,$state);
	foreach(@output) {
		$state=$1 if /state = (.*)/;
		if(/np =/){
			$np=$_;
			$np=$1 if $np=~/np = (\d*)/;
			$np=1 if not defined $np;
			$total_cpus+=$np if $state !~ /down|offline/;
			$free_cpus+=$np if $state eq "free";
		}
		if(/jobs =/){
			s/[^,]//g;
			$free_cpus-=1+length($_) if $state eq "free";
		}
	}
	($free_cpus,$total_cpus);
}

sub process_queues 
{	# process information from qstat -Q -f
	my ($pbs_path,$hostname)=@_;
	my %queues;
	my $queue_str=`$pbs_path/qstat -Q -f 2>/dev/null`;
	my @raw_queues=split(/\s*Queue:\s+/,$queue_str);
	foreach my $queue (@raw_queues){
		my ($qname)=($queue=~/(.*)\s+/);#first line has queue name
		if($queue=~m/queue_type = Execution/) { # must be execution queue
			if($queue=~/acl_host_enable = True/) {
				if ($queue=~/acl_hosts = (.*)/){
					my $acl=1;
					foreach my $name (split(/,/,$1)){
						$acl=0 if $name eq $hostname;
					}
					next if $acl eq 1;	# if host not able to submit to this queue, skip queue
				}
			}
			if($queue=~/enabled = True/ and $queue=~/started = True/) { # if queue is not enable or started, skip queue
				$queues{$qname}{MaxTotalJobs}=$1								if $queue=~/max_queuable = (\d*)/;
				$queues{$qname}{TotalJobs}=$1									if $queue=~/total_jobs =\s+(\d*)/;
				$queues{$qname}{MaxCPUTime}=tominutes($1)					if $queue=~/resources_max.cput = (.*)/;
				$queues{$qname}{MaxWallClockTime}=tominutes($1)			if $queue=~/resources_max.walltime = (.*)/;
				if($queue =~ /state_count =\s+Transit:(\d*)\s+Queued:(\d*)\s+Held:(\d*)\s+Waiting:(\d*)\s+Running:(\d*) Exiting:(.*)/){
					$queues{$qname}{WaitingJobs}=int($2+$3+$4); # queued + waiting + held
					$queues{$qname}{RunningJobs}=$5;
					#$queues{$qname}{'jobs_transit'}=$1;
					#$queues{$qname}{'jobs_exiting'}=$6;
				}
				foreach my $type ('group','user') {
					if($queue=~/acl_${type}_enable = True/){
						if ($queue=~/acl_${type}s = (.*)/){
							foreach my $name (split(/,/,$1)){
								$queues{$qname}{ACL}{$name}=1;
							}
						}
					}
				}
			}
		}
	}
	%queues;
}

sub tominutes 
{	# covert time from pbs to minutes
	my ($time) = @_;
	my ($hours, $minutes, $second) = ($time =~ /(\d+):(\d+):(\d+)/);
	return ($hours*60) + $minutes;
}


#!/usr/bin/perl
use strict;

#include some mip functions
my %mip_config=do "$ARGV[2]/source.pl";
my $mip_path=$mip_config{mipdir};
use lib::functions;
use lib::utilityfunctions;

my (%config,$vo_map,$condor_path,%vo_list,%printq,$condor_host);
my ($version_output,$status_out,$blank,$user_vo);

#get config values
my %config=do "$ARGV[2]/osg-conf.pl";
my $vo_map="$config{vdt_location}/$config{vo_map}";
my $condor_path=$config{condor_path};
$ENV{CONDOR_CONFIG}=$config{condor_config};

$printq{LRMSType}="Condor";
$printq{JobManager}="condor";

# FIXME: Is this always required?!
#get condor host..this is needed for later condor_status queries
#$condor_host=`$condor_path/condor_config_val CONDOR_HOST`; # Should get collector for collector name and port
$condor_host=`$condor_path/condor_config_val COLLECTOR_HOST`;
chomp $condor_host;

$version_output=`$condor_path/condor_version`;
$printq{LRMSVersion}=$1 if ($version_output=~/CondorVersion:\s+([\d+|.]*)/);

open(VOFILE,"<$vo_map") or die "vo_map not found";
while (<VOFILE>){
   if (! (m/^\#/ || m/^\s*$/)) {
      chomp;
      ($blank,$user_vo)=split /\ /;
      $vo_list{$user_vo}='';
   }
}
close(VOFILE);

#parse machine status 
$status_out=`$condor_path/condor_status -pool $condor_host  -total`;
my ($total_cpus, $idle_cpus, $matched_cpus, $preempting)=$status_out=~/Total\s+(\d+)\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)/;
$printq{MaxRunningJobs}=$total_cpus               if defined $total_cpus;
$printq{FreeJobSlots}  =$idle_cpus                if defined $idle_cpus;
$printq{RunningJobs}   =$total_cpus-$idle_cpus    if defined $total_cpus and defined $idle_cpus;
$printq{WaitingJobs}   =$matched_cpus+$preempting if defined $matched_cpus and defined $preempting;

# TODO: I'm not exactly sure how to handle these two values...
$printq{MaxTotalJobs}=$total_cpus if defined $total_cpus;
$printq{TotalJobs}   =$printq{RunningJobs}+$printq{WaitingJobs} if defined $printq{RunningJobs} and defined $printq{WaitingJobs};

$printq{ACL}={};
foreach my $vo (keys %vo_list){
   my $voview = "VOView LocalID=\"$vo\"";
   addelement($printq{ACL},"Rule",$vo);
   $printq{$voview}{ACL}{Rule}="VO:$vo";
   ($printq{$voview}{RunningJobs},$printq{$voview}{WaitingJobs},$printq{$voview}{TotalJobs})=(0,0,0);
   $printq{$voview}{FreeJobSlots}=$printq{FreeJobSlots} if defined $printq{FreeJobSlots};
}

#parse condor_status output
$status_out=`$condor_path/condor_status -submitter -pool $condor_host -format '%s:' Name -format '%d:' RunningJobs -format '%d:' IdleJobs -format '%d:\n' HeldJobs`;
my @vo_jobs=split(/\n/,$status_out);
foreach my $vo_job_count (@vo_jobs){
   my ($name, $running, $idle, $held) = split(/:/, $vo_job_count);
   my $waiting=$idle+$held if defined $idle and defined $held;
   my $vo=$1 if $name =~ /\s*(.*)@.*/;

   my $ignore = 1;
   foreach my $real_vo (keys %vo_list){
      $ignore = 0 if $vo=~/^$real_vo/;
   }
   next if $ignore==1;

   my $voview="VOView LocalID=\"$vo\"";
   $printq{$voview}{RunningJobs}=$running if defined $running;
   $printq{$voview}{WaitingJobs}=$waiting if defined $waiting;
   $printq{$voview}{TotalJobs}  =$running + $waiting if defined $running and defined $waiting;

   # no need to redo...same as global FreeJobSlots
   #$printq{$voview}{FreeJobSlots} = $printq{FreeJobSlots} if defined $printq{FreeJobSlots};
}

#output as XML
fastprocessor(\%printq);


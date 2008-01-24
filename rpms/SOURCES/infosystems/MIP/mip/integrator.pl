#!/usr/bin/perl -w
use strict;
use lib::utilityfunctions;
use lib::functions;
# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my $configdir=$ARGV[0];

my (%config,$int_cache,$mipdir,$ssl_file,$moduledir,$port,$usessl,$listen_socket,%hosts);
exit 1 if not -d $configdir;

%config=do "$configdir/int-conf.pl";
($int_cache,$ssl_file,$port,$usessl)=($config{int_cache},$config{ssl_file},$config{port},$config{usessl});
%config=do "$configdir/source.pl";
$moduledir=$config{moduledir};

die "moduledir does not exist" if not -d "$moduledir/int";

$SIG{CHLD} = 'IGNORE';

if($usessl eq 1) {
	use IO::Socket::SSL;
	$listen_socket = IO::Socket::SSL->new(
			LocalPort => $port,
			Listen => 8, # Allow 8 processes to queue up
			Proto => 'tcp',
			Reuse => 1,
			SSL_key_file => $ssl_file,
			SSL_cert_file => $ssl_file,
			SSL_ca_file => $ssl_file,
	);
	die "Can't create a listening socket: $@" unless $listen_socket;
} else {
	use IO::Socket;
	$listen_socket = IO::Socket::INET->new(
			LocalPort => $port,
			Listen => 8, # Allow 8 processes to queue up
			Proto => 'tcp',
			Reuse => 1,
	);
	die "Can't create a listening socket: $@" unless $listen_socket;
}
print "MIP Integrator waiting for remote MIP connections ... \n";

while (my $connection = $listen_socket->accept)
{   
	my $child;
	die "Can't fork: $!" unless defined ($child = fork());
	if ($child == 0) {
		$listen_socket->close;
		%config=do "$configdir/int-conf.pl";
		if($config{hostlist}) {
			%hosts=map{$_=>1} @{$config{hostlist}};
			#FIXME: Need to map FQDN to IP addresses
			if(not $hosts{$connection->peerhost}) {
				my $rejhost=$connection->peerhost;
				print "$rejhost rejected - Not on the host list\n";
				exit 1;
			}
		}
		integrator($connection);
		exit 0;
	} else {
		print "Remote MIP @ ",$connection->peerhost,"\n";
		$connection->close();
	}
} 

sub integrator
{  #get information from remote mip then make sure mip will produce it 
	my ($socket) = @_;
	my ($node,$root,$cluster,$uid);
	my (@arr,$loc,%hsh);

	$node=$socket->peerhost;
	while(<$socket>) { 
		push(@arr," $_"); 
	}
	$loc=0;
	xmlparser(\@arr,\$loc,'',\%hsh);
	foreach $root (keys %hsh) {
		foreach $cluster (keys %{$hsh{$root}}) {
			foreach $uid (keys %{$hsh{$root}{$cluster}}) {
				addfile($int_cache,$root,"***$node***$cluster***$uid",\%{$hsh{$root}{$cluster}{$uid}});
				addtoconfig($root,$cluster,$uid,$configdir);
				checkint($moduledir,$root);
			}
		}
	}
	$socket->close();
	return 0; 
}

sub addfile
{	# add or update the information from remote mip in the int cache 
	my ($int_cache,$root,$file,$hsh)=@_;
	system("mkdir $int_cache/$root") if not -d "$int_cache/$root";
	$file="$int_cache/$root/$file";
	open(OLDOUT, ">&STDOUT");
	open STDOUT, ">$file" or die "Can't open $file : $!";
	processor($hsh);
	close STDOUT;
	open(STDOUT, ">&OLDOUT");
	close OLDOUT;
}

sub addtoconfig
{	# check if the information from remote mip is new, if so add it to the config file
	my ($root,$cluster,$uid,$configdir)=@_;
	my (%hsh,$str,%uniq,@arr,%uids,$croot,$ccluster,$cuid);
	my ($change,$configfile)=(0,"$configdir/int.pl");

	%hsh=do "$configfile";

	#Add cluster to list
	@arr=(@{$hsh{clusterlist}});
	push(@arr,$cluster);
	%uniq=map { $_ => 1 } @arr;
	$change=1 if scalar @arr eq scalar keys %uniq; # if all entries are unique, theres a new item
	@arr=(keys %uniq);

	#Add uid to list
	push(@{$hsh{uids}{$root}},"$uid");
	%uniq=map { $_ => 1 } @{$hsh{uids}{$root}};
	$change=1 if scalar @{$hsh{uids}{$root}} eq scalar keys %uniq; # if all entries are unique, theres a new item
	@{$hsh{uids}{$root}}=(keys %uniq);

	if($change eq 1) { # If change the re-write config file
		#Print cluster list
		$str="clusterlist => [ \n";
		foreach $ccluster (@arr) {
			$str="$str                 \'$ccluster\', \n";
		}
		$str="$str               ], \n";

		#Print uid list	
		$str="${str}\nuids => { \n";
		foreach $croot (keys %{$hsh{uids}}) {
			$str="$str          $croot => \n                     [ \n";
			foreach $cuid (@{$hsh{uids}{$croot}}) {
				$str="$str                       \'$cuid\', \n";
			}
			$str="$str                     ], \n";
		}
		$str="$str        } \n";

		print "Change noticed: updating configuration file\n";
		open F, "> $configfile" or die "Can't open $configfile : $!";
		print F $str;
		close F;
	}
}

sub checkint
{	# Check to see if Integrator has an instance that that root, if not add it
	my ($moduledir,$root)=@_;

	if(! -d "$moduledir/int/$root") {
		mkdir("$moduledir/int/$root",0755) or die "cannot create integrator directory";
		symlink("$moduledir/int/.integrator","$moduledir/int/$root/$root") or die "cannot symlink file";
	}
}



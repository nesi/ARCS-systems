#!/usr/bin/perl
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

my $configdir=$ARGV[0];

my (%config,$socket,$mip,$integrator,$ssl_file,$socket,$port,$usessl);

exit 1 if not -d $configdir;

%config=do "$configdir/source.pl";
$mip=`$config{mipdir}/mip rawxml 2>/dev/null`;
%config=do "$configdir/remote-conf.pl";
($integrator,$ssl_file,$port,$usessl)=($config{integrator},$config{ssl_file},$config{port},$config{usessl});
$integrator=$ARGV[1] if $ARGV[1];

if($usessl eq 1) {
	use IO::Socket::SSL;
	$socket = new IO::Socket::SSL (  
		PeerAddr => $integrator,
		PeerPort => $port,
		Proto => 'tcp',
		SSL_key_file => $ssl_file,
		SSL_cert_file => $ssl_file,
		SSL_ca_file => $ssl_file,
	);
	die "Could not create socket: $!\n" unless $socket;
} else {
	use IO::Socket;
	$socket = new IO::Socket::INET (  
		PeerAddr => $integrator,
		PeerPort => $port,
		Proto => 'tcp',
	);	
	die "Could not create socket: $!\n" unless $socket;
}

print $socket $mip or die "Could not send information to socket";
$socket->close();


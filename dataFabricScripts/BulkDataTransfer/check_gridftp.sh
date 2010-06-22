#!/usr/bin/env perl
# check_gridftp.pl  Nagios script for GridFTP.
#                   Graham Jenkins <grahjenk@vpac.org> June 2010. Rev: 20100622

use strict;
use warnings;
use File::Basename;
use IO::Socket;
use vars qw($VERSION);
$VERSION = "1.01";

# Check usage
die "Usage: ".basename($0)." server port\n".
    " e.g.: ".basename($0)." df.arcs.org.au 2810\n"
  if ( ( $#ARGV != 1 ) || ( $ARGV[1] !~ m/^\d+$/ ) ); 

# Attempt connection
my $socket = IO::Socket::INET->new( PeerAddr=>$ARGV[0], PeerPort=>$ARGV[1],
                                    Proto=>'tcp'      , Timeout=>5 )
  or do_exit("CRITICAL", $@, 2);

# Get and check response
my $response;
if ( ! defined ( $response = <$socket> ) ) { do_exit("CRITICAL", $@, 2) }
chomp($response);
if ( $response =~ m/GridFTP Server/      ) { do_exit("OK", $response, 0)}
else          { do_exit("WARNING", "Unexpected response: ".$response, 1)}

# Exit subroutine
sub do_exit {
  print "GRIDFTP ".$_[0]." - ".$_[1],"\n";
  close;
  exit ($_[2])
}

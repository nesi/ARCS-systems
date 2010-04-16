#!/usr/bin/env perl
# syncTest.pl Prints the user-list XML file supplied by the ARCS
#             Access Service.
#             Graham Jenkins <graham@vpac.org> April 2010. Rev: 20100412
use strict;
use warnings;
use File::Basename;       # You may need to do:
use LWP::UserAgent;       # yum install perl-Crypt-SSLeay

# Adjust these as appropriate:
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates";
$ENV{HTTPS_CERT_FILE} = "/etc/grid-security/irodscert.pem";
$ENV{HTTPS_KEY_FILE}  = "/etc/grid-security/irodskey.pem";
$ENV{HTTPS_DEBUG} = 0;    # Set to "1" to enable debug
my $URL="https://access.arcs.org.au/service/list.html?serviceId=3";

# Get and print the current user list
die "Usage: ".basename($0)."\n" if $#ARGV >= 0;
my $agent = LWP::UserAgent->new;
my $response = $agent->get($URL);
if ( $response->is_success ) {print $response->content,"\n"; exit 0}
else                         {print "Failed!\n";             exit 1}

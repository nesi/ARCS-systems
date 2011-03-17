#!/usr/bin/env perl
# createUser     Creates a new password for an iRODS user during "Real-Shib"
#                login. Exits with error if the user does not exist.
#                Graham Jenkins <graham@vpac.org> Dec. 2008. Rev: 20101018

use strict;
use warnings;
use File::Basename;
use Sys::Syslog;
use vars qw($VERSION);
$VERSION = "4.05";
my $debug="N";   # Set to "Y" or "N" as appropriate

# Log-and-die subroutine
sub log_and_die { # Usage: log_and_die(message)
  syslog("info",$_[0]." "."[pid=".$$."]");
  die($_[0])
}

# Check usage
die basename($0)." should not be invoked by a normal user\n"
  if ( defined($ENV{spClientUser}) && $ENV{spClientUser} ne "rods" );
die "Usage: ".basename($0)." FirstName .. LastName SharedToken Password"."\n".
    " e.g.: ".basename($0).' Jane Doe VI8SEdbk_8Ph3E7M1O8jdABRAC2 GuessMe'."\n"
  if ( ($#ARGV < 2) || ($ARGV[0] !~ m/^[A-Za-z]/) );

# Extract CN, generate extended shared-token and get matching username
my $cn=$ARGV[0];
for (my $j=1;$j<($#ARGV-1);$j++) { $cn.=" ".$ARGV[$j] }
log_and_die("Invalid ST for: ".$cn." ".$ARGV[$#ARGV-1]." xxxx")
  if (length($ARGV[$#ARGV-1]) != 27);
my $stplus="'%<ST>".$ARGV[$#ARGV-1]."</ST>%'";
my $username=
  `iquest "%s" "SELECT USER_NAME where USER_INFO like $stplus" 2>/dev/null`;
chomp($username);
log_and_die("Username not found for: ".$cn." ".$ARGV[$#ARGV-1]." xxxx") 
  if (length($username)<1);

# Set the password for the matching username and exit
syslog("info","iadmin moduser $username password $ARGV[$#ARGV] "."[pid=".$$."]")
  if $debug eq "Y";
`iadmin moduser $username password $ARGV[$#ARGV]`;
log_and_die("Failed to set password for user: ".$username) if ($?);
exit(0)

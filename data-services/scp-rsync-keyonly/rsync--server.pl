#!/usr/bin/env perl
# Gareth.Williams csiro.au Tue Mar 29 2005
# rsync--server.pl
#
# a script to be run as a forced command in .ssh/authorized_keys to 
# allow rsync download from limited locations
# and no other ssh access with the key
# 
# parses $SSH_ORIGINAL_COMMAND and only allows rsync --server
#   with --sender if the -s option is given
# with a limited range of paths
#
# Oct 2009, allow path in rsync command

use strict;
use warnings;
use Getopt::Std;
my %opts;
getopts('vs', \%opts);
my $verbose = 0;
if (exists $opts{'v'}) {
    $verbose = 1;
} else { # try to be very quiet
    open STDERR, '>/dev/null';
}
my $sender = 0;
my $sender_only = 0;
$sender_only = 1 if exists $opts{'s'};

%opts = (); # may be re-used

print STDERR "rsync--server.pl filter running - will only allow rsync up/download 
  to/from a set list of files/directories\n" if $verbose;

my @allowed_downloads = ();
my @allowed_destinations = ();

# note. customize this list or leave it empty ()
# eg. 1
@allowed_downloads = ( 'download/index', 'download/file1',
  'download/file2', 'download/dir1/', 'download/dir2/');
#@allowed_downloads = ( 'satellite_data/',
#                       'satellite_data/noaa',
#                       'satellite_data/noaa/');

print STDERR "allowed files/paths for download:\n'",
             join("'\n'", @allowed_downloads), "'\n" if $verbose;

unless ($sender_only) {
    # note. customize this list or leave it empty ()
    # eg. 1
    @allowed_destinations = ( 'upload/dir1/', 'upload/dir2/');
    
    print STDERR "allowed destinations for upload:\n",
                 join("\n", @allowed_destinations), "\n" if $verbose;
}

#this could be useful
#my $c = (split(/ /,$ENV{SSH_CLIENT}))[0]; #client IP

# expecting SSH_ORIGINAL_COMMAND to have only simple characters
print STDERR "SSH_ORIGINAL_COMMAND: '$ENV{SSH_ORIGINAL_COMMAND}'\n" if $verbose;
if( ! exists $ENV{SSH_ORIGINAL_COMMAND}) {
    &bailout("no SSH_ORIGINAL_COMMAND\n");
} elsif (! $ENV{SSH_ORIGINAL_COMMAND} =~ /^[\w .-:\/]+$/) {
    # only expecting a-zA-Z0-9_, space, ., -, /, :
    # could consider ,*@~()[]{}\?'"+=`
    # certainly don't want ;, &, |
    &bailout("unexpected characters in SSH_ORIGINAL_COMMAND\n");
}

# split up command to parse
# simple split on whitespace - will not work with filenames with spaces 
@ARGV = split / /,$ENV{SSH_ORIGINAL_COMMAND};
#print STDERR "SSH_ORIGINAL_COMMAND:\n", "'", join("'\n'", @ARGV), "'\n" if $verbose;
my @cmdlist = @ARGV;

# the first word is the command - should be rsync
my $cmd = shift @ARGV;
$cmd =~ /rsync$/ or &bailout("SSH_ORIGINAL_COMMAND not 'rsync'\n");
# only run the default rsync from PATH
$cmdlist[0] = 'rsync';

# the second word should be --server
my $flag = shift @ARGV;
$flag eq '--server' or &bailout("SSH_ORIGINAL_COMMAND not 'rsync --server'\n");

if ($sender_only) { # the third word should be --sender
    $flag = shift @ARGV;
    $flag eq '--sender' or &bailout("SSH_ORIGINAL_COMMAND not 'rsync --server --sender'\n");
    $sender = 1;
} elsif ($ARGV[0] eq '--sender') {
    $sender = 1;
}

# the last words should be . and the list of sources (or the dest)
my ($dot, $paths) = (0, 0);
my $path;
foreach $path (reverse @ARGV) {
    print STDERR "rsync--server.pl considering path '$path'\n" if $verbose; 
    if ($path eq '.') {$dot = 1; last
    } elsif ( $sender and grep { $path eq $_ } @allowed_downloads ) { $paths++
    } elsif ( ! $sender and grep {$path eq $_} @allowed_destinations ) { $paths++
    } else { &bailout("path option not allowed\n")
    }
}
&bailout("expected path arguments not found\n") unless ($dot and $paths);
&bailout("multiple path arguments found\n") if ( (! $sender) and $paths > 1);

exec @cmdlist;

sub bailout {
    print STDERR "rsync--server.pl filter bailing out: ", shift if $verbose;
    exit 1;
}

#!/usr/bin/env perl
# Gareth.Williams csiro.au Tue Mar 22 2005
# scp-ft.pl
#
# a script to be run as a forced command in .ssh/authorized_keys to 
# allow scp upload or download to/from a limited locations
# and no other ssh access with the key
# 
# parses $SSH_ORIGINAL_COMMAND and only allows scp -f  or scp -t with 
# a limited range of paths

use strict;
use warnings;
use Getopt::Std;
my %opts;
getopts('v', \%opts);
my $verbose = 0;
if (exists $opts{'v'}) {
    $verbose = 1;
    %opts = (); # will be re-used
} else { # try to be very quiet
    open STDERR, '>/dev/null';
}

print STDERR "scp-ft.pl filter running - will only allow scp download of a 
  set list of files or upload to a specific set of destinations\n" if $verbose;

# note. customize this list or make it empty ()
# eg. 1
#my @allowed_downloads = ( 'download/index', 'download/file1',
#  'download/file2', 'download/dir1/', 'download/dir2/');
# eg. 2
#my @allowed_downloads = ();
my @allowed_downloads = ( 'download/index', 'download/file1',
  'download/file2', 'download/dir1/', 'download/dir2/');

print STDERR "allowed files/paths for download:\n",
             join("\n", @allowed_downloads), "\n" if $verbose;

# note. customize this list or make it empty ()
# eg. 1
#my @allowed_destinations = ( 'upload/dir1/', 'upload/dir2/');
# eg. 2
#my @allowed_destinations = ();
my @allowed_destinations = ( 'upload/dir1/', 'upload/dir2/');

print STDERR "allowed destinations for upload:\n",
             join("\n", @allowed_destinations), "\n" if $verbose;

#this could be useful
#my $c = (split(/ /,$ENV{SSH_CLIENT}))[0]; #client IP

# expecting an scp -f or -t command
if( ! exists $ENV{SSH_ORIGINAL_COMMAND}) {
    &bailout("no SSH_ORIGINAL_COMMAND\n");
}
print STDERR "SSH_ORIGINAL_COMMAND: $ENV{SSH_ORIGINAL_COMMAND}\n";

# split up command to parse with getopts
@ARGV = split / /,$ENV{SSH_ORIGINAL_COMMAND};

# the first word is the command - should be scp
my $cmd = shift @ARGV;
$cmd eq 'scp' or &bailout("SSH_ORIGINAL_COMMAND not 'scp'\n");

# start (re-)constructing command
my @a = ('scp');

getopts('ftrpv', \%opts);

&bailout("SSH_ORIGINAL_COMMAND, scp lacks path argument\n") if ($#ARGV < 0);
&bailout("SSH_ORIGINAL_COMMAND, scp has unexpected arguments") if ($#ARGV > 0);

#remaining arg - should be an allowed path
my $path = shift @ARGV;

# expecting -f or -t
if (exists $opts{'f'}) {
    &bailout("SSH_ORIGINAL_COMMAND 'scp' with '-t and -f'!\n")
        if (exists $opts{'t'});
    push @a, '-f';
    grep {$path eq $_} @allowed_downloads
        or &bailout("requested path not allowed\n");
} elsif (exists $opts{'t'}) {
    push @a, '-t';
    grep {$path eq $_} @allowed_destinations
        or &bailout("requested path not allowed\n");
} else {
    &bailout("SSH_ORIGINAL_COMMAND not 'scp -f' or 'scp -t'\n");
}

# add allowed options
push @a, '-p' if exists $opts{'p'};
push @a, '-r' if exists $opts{'r'};
push @a, '-v' if exists $opts{'v'};

push @a, $path;

exec @a;

sub bailout {
    print STDERR "scp-ft.pl filter bailing out: ", shift if $verbose;
    exit 1;
}

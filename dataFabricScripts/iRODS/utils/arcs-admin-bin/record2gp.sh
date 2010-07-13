#!/usr/bin/env perl
# $Id$
# $HeadURL$
use strict;
use warnings;
use Date::Manip;
# reads lines like:
#Wed Apr 21 00:00:01 EST 2010 .. Jobs for user(s): rods,davis,jetty
#   VSZ   RSS USER       PID COMMAND
#1405636 569932 davis   4038 java
#438568 86740 jetty     5634 java
#253152 245364 rods     3857 irodsServer
# 13312  4652 rods      5246 irodsAgent
# 12268  5668 rods      5508 irodsAgent
# 11484  4368 rods      3858 irodsReServer
# 11236  5312 rods     28547 irodsAgent
# 11072  4380 rods      6073 irodsAgent
#  9028  2060 rods      6076 crond
# and outputs data for gnuplot...
my %process;
my $time;
while (my $line = <>) {
  if ($line =~ /^(\w+\s+\w+\s+\d+\s+\d\d:\d\d:\d\d\s+\w+\s+\d\d\d\d) .. Jobs/) {
    my $match = $1;
    $match =~ s/EST/AEST/;
    $time = UnixDate(ParseDate($match), "%s");
  } elsif ($line =~ /VSZ/) {
    next;
  } elsif ($line =~ /^\s*(\d+)\s+(\d+)\s+(\w+)\s+(\d+)\s+([\w.]+)\s*$/) {
    my ($vsz, $rss, $user, $pid, $cmd) = ($1, $2, $3, $4, $5);
    next unless $vsz > 50000;
    my $key = "$cmd.$pid.$user";
    $process{$key} = () unless exists $process{$key};
    push @{$process{$key}}, "$time $vsz";
  } elsif ($line =~ /^[\s-]*$/) {
    next;
  } else {
    print STDERR "line not matched: $line";
  }
}
print "set timestamp top\nset xlabel 'date/time'\nset ylabel 'size(Bytes)'\nset title 'vmem used by rods processes'\nset terminal png\nset pointsize 0.4\nset xdata time\nset format x '%H:%M'\nset key outside\nset timefmt '%s'\nset xtics 60*60*4\nplot \\\n";
my @plots;
foreach my $key (keys %process) {
  push @plots, "'-' u (\$1+10*60*60):2 w lp t '$key' \\\n";
}
print join ",\\\n", @plots;
print "\n";
foreach my $key (keys %process) {
  print "#$key\n";
  print join "\n", sort @{$process{$key}};
  print "\ne\n";
}

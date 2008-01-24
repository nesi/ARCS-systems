#!/usr/bin/perl -w

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

use strict;

use lib::functions;
use lib::utilityfunctions;
use lib::producers;
my %config= do 'config/source.pl';
 
my ($mipdir,$moduledir,$configdir,@pkgs,$produce,%hsh);

$mipdir=$config{mipdir};
$mipdir=~s/ /\\ /g; # Escape spaces
$moduledir=$config{moduledir};
$moduledir=~s/ /\\ /g; # Escape spaces
$configdir=$config{configdir};
$configdir=~s/ /\\ /g; # Escape spaces
@pkgs=@{$config{pkgs}};

foreach my $pkg (@pkgs) {
	addhash(\%hsh,packagehandler($pkg,$moduledir,$configdir));
}

#Get producer as parameter or use default
$produce=$config{producer};
$produce=$ARGV[0] if defined $ARGV[0];



producer(\%hsh,$produce);

#FIXME: REMOVE THIS
use Data::Dumper;
#print Dumper(\%hsh);


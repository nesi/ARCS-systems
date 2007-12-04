#!/usr/bin/perl -w
use strict;

# Copyright © 2005-2006 Grid Research and educatiOn group @ IoWa (GROW), The University of Iowa, IA. All rights reserved.
# For more information please contact: GROW team, grow-tech@grow.uiowa.edu

sub packagehandler
{	# Add all information from modules in a certain package
	my ($pkg,$moduledir,$configdir)=@_;
	my (%hsh,%subhsh,%config,@clusterlist,%uids);

	return {} if not -e "$configdir/$pkg.pl";
	
	%config= do "$configdir/$pkg.pl";
	@clusterlist=@{$config{clusterlist}};
	%uids=%{$config{uids}};

	foreach my $root (keys %uids) {
		foreach my $cluster (@clusterlist) {
			foreach my $uid (@{$uids{$root}}) {
				%subhsh=%{moduleaggregator("$moduledir/$pkg/$root",$cluster,$uid,$configdir)};
				if(%subhsh) {
					%subhsh=($root => {$cluster => {$uid => {%subhsh}}});
					addhash(\%hsh,\%subhsh);
				}
			}
		}
	}
	return \%hsh;
}

################## 		MODULES			####################

sub moduleaggregator
{	# Aggregate all module information
	my ($moduledir,$cluster,$uid,$configdir)=@_;
	my (%hsh,@arr,$loc,@modulelist);
	@modulelist=listmodules($moduledir);
	foreach my $module (@modulelist) {
        @arr=runmodule($module,$cluster,$uid,$configdir);
        $loc=0;
        xmlparser(\@arr,\$loc,'',\%hsh);
	}
	return \%hsh;
}

sub runmodule
{	# Execute the module and return its output
	my ($module,$cluster,$uid,$configdir)=@_;
	$module=~s/ /\\ /g; # Escape spaces
	$configdir=~s/ /\\ /g; # Escape spaces
	$uid=~s/"/\\"/g; #Escape quotes
	my @ret=();
	eval {
		local %SIG;
		$SIG{ALRM}=sub{ die "Module timed out"; };
		alarm 60;
		@ret=`$module "$cluster" "$uid" "$configdir"`;
		alarm 0;
	};
	@ret=() if $@;
	@ret;
}

sub listmodules
{	# Get a list of modules in a certain directory
	my $dirname=$_[0];
	my ($file,@list)=('',());
	opendir(DIR, "$dirname") or return ();
	while ($file=readdir(DIR)) {
		# a fix so a the swp file inside the directory won't be added
		# to the list of files to be executed
		#push(@list,"$dirname/$file") if not -d "$dirname/$file";
		my $module = "$dirname/$file";
		push(@list,"$dirname/$file") if not -d "$module" && not $module =~ /swp$/;
	}
	closedir(DIR);
	@list;
}

#####################		PRINT TAGS 		###################
sub startelement
{	# print <Element attr="some attr">
	my ($str,$l,$r,@list);
	($l,$r)=split(/ /,$_[0],2);
	$l=$1 if $l=~/\s*(.+)\s*/;
	$str="<$l";
	while($r) {
		$r=$1 if $r=~/\s*(.+)\s*/;
		($l,$r)=split(/=/,$r,2);
		if (not $r) {
			$str="$str$l";
			next;
		}
		@list=split(/"/,$r,3);
		if($list[1]) { #if quoted take the quotes, else take text
			$r=$list[1];
		} else {
			$r=$list[0];
		}
		$str="$str $l=\"$r\"";
		$r=$list[2];
	}
	return "$str>\n";
}

sub endelement
{	# print </Element>
	my @list=split(/ /,$_[0]);
	return  "</$list[0]>\n";
}

sub element
{	# print <Element attr="some attr">some value</Element>
	my $el=$_[0];
	($el)=elexceptionhandlerprint($el) if elexception($el);
	return "<$el />\n" if $_[1] eq '';
	return "<$el>$_[1]".endelement($el);
}

sub spaces
{	# given a number print that many spaces (used for debugprocessor)
	return " " x $_[0];
}

1;


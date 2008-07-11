#!/usr/bin/env perl

use strict;
use warnings;
use Inca::Reporter::SimpleUnit;
use Cwd;
my $reporter = new Inca::Reporter::SimpleUnit(
  name => 'data.fabric.srb.unit.sls',
  version => 1,
  description => 'This reporter tests the Sls command',
  url => 'http://www.arcs.org.au/',
  unit_name => 'sls'
);
my $dir = getcwd;
#print $dir;
$reporter->addDependency('Inca::Reporter::GridProxy');
$reporter->addArg('site');
$reporter->addArg('type', 'srb server type', 'development');

$reporter->processArgv(@ARGV);
my $site=$reporter->argValue('site');
my $type=$reporter->argValue('type');

$reporter->setUnitName($site."_Sls");

my $MDIR = "$ENV{HOME}/.srb/srb_test.$$";
mkdir $MDIR || die "couldn't make $MDIR";
$reporter->tempFile($MDIR);

my $mdasEnv="$MDIR/.MdasEnv.$$";
my $cmd="$dir/srb-env.py -m $site $type -o $mdasEnv";
#print $cmd;
`$cmd 2>&1`;
#`cp $ENV{HOME}/.srb/.MdasEnv $MDIR/.MdasEnv.$$`;
#`cp $ENV{HOME}/.srb/.MdasAuth $MDIR/.MdasAuth.$$`;
$ENV{"mdasEnvFile"} = "$MDIR/.MdasEnv.$$";
#$ENV{"mdasAuthFile"} = "$MDIR/.MdasAuth.$$";

my $output = $reporter->loggedCommand('Sinit');
if($?) {
  $reporter->unitFailure("Error during Sinit: $!:" . $output);
} else {
  $output = $reporter->loggedCommand('Sls');
  if($?) {
    $reporter->unitFailure("Error during Sls: $!" . $output);
  } else {
    $reporter->unitSuccess();
  }
}
unlink "$MDIR/.MdasEnv.$$";
#, "$MDIR/.MdasAuth.$$";
$reporter->loggedCommand('Sexit');
$reporter->print();

#!/usr/bin/env perl

use strict;
use warnings;
use Inca::Reporter::SimpleUnit;
use Cwd;

my $reporter = new Inca::Reporter::SimpleUnit(
  name => 'data.fabric.srb.unit.sls',
  version => 1.6,
  description => 'This reporter tests the Sls command',
  url => 'http://www.arcs.org.au/',
  unit_name => 'sls'
);
my $dir = $ENV{'SRB_TEST_PATH'}?$ENV{'SRB_TEST_PATH'}:$reporter->getcwd;
#print $dir;
$reporter->addDependency('Inca::Reporter::GridProxy');
$reporter->addArg('site');
$reporter->addArg('type', 'srb server type', 'development');

$reporter->processArgv(@ARGV);
my $site=$reporter->argValue('site');
my $type=$reporter->argValue('type');


my $MDIR = "$ENV{HOME}/.srb/srb_test.$$";
mkdir $MDIR || die "couldn't make $MDIR";
$reporter->tempFile($MDIR);

my $mdasEnv="$MDIR/.MdasEnv.$$";
my $cmd="$dir/srb-env.py -m $site $type -o $mdasEnv";
$reporter->log('info',$cmd);
#print $cmd;
`$cmd 2>&1`;
`cat $mdasEnv 1>&2`;

my $tmp_line=`grep 'srbHost' $mdasEnv`;
#print $tmp_line;
my $svr_name = "";
if($tmp_line =~ m#srbHost \'(.+)\'# ) {
  $svr_name = $1;
}

$reporter->setBody("<srb_site>".$site."</srb_site><srb_test>Sls</srb_test><srb_host>".$svr_name."</srb_host>");

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

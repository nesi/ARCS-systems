#!/usr/bin/perl

# Run 'Szonesync.pl -h' for usage information.

# Also see the Szonesync.pl man page.

# This script, Szonesync.pl, synchronizes information between zones,
# pulling information from the other zones and inserting it into the
# local MCAT via the Spullmeta and Spushmeta commands.  In the
# Federated MCAT system, the local MCAT needs to have certain
# information from the other zones, for example, a list of users
# (username and domain) for the remote zone (altho the password is
# kept only at the zone that is local to that user).

# Before sync'ing with another zone, you should make sure you do
# not have name conflicts with any of the following:
#   1) Domain names.  
#   2) Resource names.
#   3) Location names (locations with the same name are OK if they
#      actually refer to the same location).
# See below for more on this.
# Some of these restrictions will be removed or streamlined in future
# releases.

# This script queries the local MCAT to find which zones exist and
# where they are (host ids) and then connects to each, retrieving the
# information, and inserting it locally.  The Spullmeta and Spushmeta
# commands perform the get and put of the information.

# It is assumed that the user has set the path to include the location
# of the SRB S commands and has a valid .MdasEnv and .MdasAuth
# for connecting to the local server.

# It is also necessary that this local user id is registered as an
# admin for this zone at the remote zone(s).  For example, the local
# zone is "A", the remote is "B", and you are srbAdmin@Adomain
# locally.  At B, there must be a user defined as being in Zone A,
# with name srbAdmin@Adomain, with admin privileges (for zone A).
# When this script, via Stoken, connects to the server at B, server B
# will check with server A to verify srbAdmin@Adomain has the correct
# password.

# The list of the information that is retrieved and stored is defined
# in the code below, in the DO_LIST and DO_LIST_DATED lists (this is a
# subset of what Spullmeta and Spushmeta can do).  Many values are
# needed locally to match the foreign Zone.  For example, the
# pull/push of GET_USER_TYPE returns all the user types defined in the
# foreign zone and defines them in the local zone.

# Another important set of information is the user ids.  IT IS ASSUMED
# THAT THERE ARE NO USER NAME CONFLICTS BETWEEN ZONES.  That is,
# user@domain will always be unique across the Federation.  So you
# must be sure that your domains are unique, as well as the zones.

# Similarly, resources also need to be uniquely named across the
# federation of zones if they actually refer to a different resource.

# This script, via Spushmeta, will insert new items into the local
# MCAT.  In some cases, existing items will be left alone and in
# others they wil be overwritten.  We'll be documenting this shortly.

# This script produces a file for each datatype that is pulled and
# pushed, in case you need to look at them.  So it is best to run this
# script in an empty subdirectory to keep them straight.

# Spullmeta and Spushmeta can pull and push many types of meta data
# (run Spullmeta with no options for a list).  What is included below
# is a subset that you are very likely to need.  If you find that
# other values need to be sync'ed, you can add them to the DO_LIST or
# DO_LIST_DATED lists.

# There is a command line flag, -r, for if you'd like to sync the
# resources too.  This will pull and push a number of resource
# associated items so that both zones will be fully "aware" of the
# other's resources.  See DO_LIST_RESC and DO_LIST_RESC_DATED for the
# list of items.

# By default below, we do not include the GET_CHANGED_ZONE_INFO
# option, as that would cause local information on remote zones to be
# overwritten with the remote zone information.  Generally, you define
# remote zones by hand to bootstrap the zone/federation creation
# process.

# The GET_CHANGED_* options return information that has changed since
# the specified date.  For this version, we are simply using a past
# timestamp for this.  A future release will be a little more
# efficient by recording the last sync time for this zone and using
# that.


# The following four lists can be edited to add or substract items to
# sync.  $DO_LIST and $DO_LIST_DATED are the items that are done by
# default.  $DO_LIST_RESC and $DO_LIST_RESC_DATED are are added in
# with $DO_LIST and $DO_LIST_DATED when the -r command is included.
# The ones with _DATED ($DO_LIST_DATED and $DO_LIST_RESC_DATED) are
# those that require the date format to the Spullmeta command.  Run
# 'Spullmeta' (without options) to get a list of the available items
# that can be sync'ed.

$DO_LIST="GET_USER_TYPE GET_USER_DOMAIN";
$DO_LIST_DATED="GET_CHANGED_USER_INFO";

$DO_LIST_RESC="GET_RESOURCE_TYPE GET_RESOURCE_CLASS GET_RESOURCE_ACCESS_CONSTRAINT";
$DO_LIST_RESC_DATED="GET_LOCATION_INFO GET_CHANGED_PHYSICAL_RESOURCE_CORE_INFO GET_CHANGED_LOGICAL_RESOURCE_CORE_INFO GET_CHANGED_RESOURCE_OTHER_INFO GET_CHANGED_RESOURCE_UDEF_METADATA GET_CHANGED_RESOURCE_ACCESS";

$DO_LIST_DATA="GET_CONTAINER_INFO";
$DO_LIST_DATA_DATED="GET_CHANGED_COLL_CORE_INFO GET_CHANGED_DATA_CORE_INFO GET_CHANGED_DATA_ACCESS GET_CHANGED_COLL_ACCESS GET_CHANGED_COLLCONT_INFO GET_CHANGED_DATA_UDEFMETA_INFO GET_CHANGED_COLL_UDEFMETA_INFO GET_CHANGED_DATA_ANNOTATION_INFO GET_CHANGED_COLL_ANNOTATION_INFO GET_CHANGED_OTHERDATA_INFO GET_CHANGED_DATA_GUID_INFO";


($arg1, $arg2, $arg3)=@ARGV;

if ($arg1 eq "-z") {
    $argZoneName = $arg2;
}
if ($arg2 eq "-z") {
    $argZoneName = $arg3;
}

$OK=0;
if ($arg1 eq "-u" | $arg3 eq "-u") {
    $OK=1;
}

if ($arg1 eq "-r" | $arg3 eq "-r") {
    $OK=1;
    $DO_LIST = $DO_LIST . " " . $DO_LIST_RESC;
    $DO_LIST_DATED = $DO_LIST_DATED . " " . $DO_LIST_RESC_DATED;
}

if ($arg1 eq "-d" | $arg3 eq "-d") {
    $OK=1;
    $DO_LIST = $DO_LIST_DATA;
    $DO_LIST_DATED = $DO_LIST_DATA_DATED;
}

if ($arg1 eq "-h" | $OK eq "0") {
    print "Usage: Szonesync.pl -r|u|d [-z zone]\n";
    print "Options:\n";
    print "  Szonesync.pl -u      will do a user info (basic) sync.\n";
    print "  Szonesync.pl -r      will do user plus resource information.\n";
    print "  Szonesync.pl -d      will do data information.\n";
    print "  Szonesync.pl -z name will sync only from the named zone.\n";
    print "                      by default, all remote zones are done.\n";
    print "  Szonesync.pl -h [or nothing] prints this help.\n";
    print "Szonesync.pl synchronizes information from remote zones.\n";
    print "All zones must be defined in the MCAT before running Szonesync.pl.\n";
    print "To customize what is sync'ed, you can edit some lists in the \n";
    print "script (see the comments for how to do this).\n";
    print "To see what MCAT items can be sync'ed, run 'Spullmeta'.\n";
    print "See the beginning of the script for more.\n";
    exit();
}

if (!-e "./SzonesyncTmpDir") {
    print "mkdir'ing: ./SzonesyncTmpDir\n";
    mkdir("SzonesyncTmpDir", 0700);
}
print "chdir'ing to: ./SzonesyncTmpDir\n";
chdir "./SzonesyncTmpDir" || die "Can't chdir to ./SzonesyncTmpDir\n";

$_=$DO_LIST;
@DO_LIST=split(" ", $_);

$_=$DO_LIST_DATED;
@DO_LIST_DATED=split(" ", $_);

$CHANGED_DATE="1997-01-01";
#$CHANGED_DATE=`date +%Y-%m-%d-%H-%M-%S`;

$zoneCmd="Stoken Zone";
if ($argZoneName) {
    $zoneCmd="Stoken Zone $argZoneName";
}

$stokenZone=`$zoneCmd`;
$cmdStat=$?;
if ($cmdStat!=0) {
    print "The '$zoneCmd' command failed:";
    print "Exit code= $cmdStat \n";
    die("command failed");
}
$stokenZoneIds=`echo '$stokenZone' | grep zone_id`;
$stokenLocality=`echo '$stokenZone' | grep local_zone_flag`;
$stokenPorts=`echo '$stokenZone' | grep port_number`;
$stokenNetprefix=`echo '$stokenZone' | grep netprefix`;
$stokenZoneStatus=`echo '$stokenZone' | grep zone_status`;

$_=$stokenZoneIds;
@zones=split("\n", $_);
$_=$stokenLocality;
@locality=split("\n", $_);
$_=$stokenPorts;
@ports=split("\n", $_);
$_=$stokenNetprefix;
@netprefix=split("\n", $_);
$_=$stokenZoneStatus;
@zoneStatus=split("\n", $_);

$zoneCount=0;
$inactiveZoneCount=0;
$i=0;
foreach $zones (@zones) {
#    printf("Zone %s\n",$zones);
    $zoneCount++;
    if ($zoneStatus[$i] =~ /: 0/) {
	$inactiveZoneCount++;
    }
    $i++;
}
if ($argZoneName) {
    if ($zoneCount ne "1") {
	die ("Error getting information on specified zone $argZoneName");
    }
    print "Zone $argZoneName to be processed.\n";
}
else {
    print "There are $zoneCount zones.\n";
    if ($inactiveZoneCount > 0) {
	print "Of which $inactiveZoneCount are inactive (and will be ignored)\n";
    }
}

for ($i=0;$i<$zoneCount;$i++) {
    if ($locality[$i] =~ /: 1/) {  # local
	if ($zoneStatus[$i] =~ /: 1/) { # and active
	    $name = $zones[$i];
	    $name =~ s/zone_id: //;
	    print "The local zone is: " . $name . "\n";
	}
    }
}

print "Remote zones are:  ";
for ($i=0;$i<$zoneCount;$i++) {
    if ($locality[$i] =~ /: 0/) { # remote
	if ($zoneStatus[$i] =~ /: 1/) { # and active
	    $name = $zones[$i];
	    $name =~ s/zone_id: //;
	    print $name . " ";
	}
    }
}
print "\n";

$DEBUG=1;
if ($DEBUG) {
    print "Remote ports are:  ";
    for ($i=0;$i<$zoneCount;$i++) {
	if ($locality[$i] =~ /: 0/) {  # remoter
	    if ($zoneStatus[$i] =~ /: 1/) { # and active
		$name = $ports[$i];
		$name =~ s/port_number: //;
		print $name . " ";
	    }
	}
    }
    print "\n";

    print "Remote hosts are:  ";
    for ($i=0;$i<$zoneCount;$i++) {
	if ($locality[$i] =~ /: 0/) {
	    if ($zoneStatus[$i] =~ /: 1/) { # and active
		$name = $netprefix[$i];
		$name =~ s/netprefix: //;
		$name = substr($name,0,index($name,":"));
		print $name . " ";
	    }
	}
    }
    print "\n";
}

$UsersEnvFile = glob("~/.srb/.MdasEnv");
$UsersEnvVar=$ENV{'mdasEnvFile'}; 
if ($UsersEnvVar) {
    $UsersEnvFile = glob("$UsersEnvVar"); # use user's env variable for mdasEnvFile
}

for ($i=0;$i<$zoneCount;$i++) {
    if ($locality[$i] =~ /: 0/ && $zoneStatus[$i] =~ /: 1/) {
	$zone = $zones[$i];
	$zone =~ s/zone_id: //;

	$host = $netprefix[$i];
	$host =~ s/netprefix: //;
        $host = substr($host, 0, index($host,":"));

	$port = $ports[$i];
	$port =~ s/port_number: //;

	print "Doing zone $zone which is hosted at host $host port $port\n";

	if (!$host) {
	    print "Skipping zone $zone, no host/location defined\n";
	}
        else {

# We need to set the srbHost and srbPort but also need the other items
# from the .MdasEnv file.  So copy it substituting the hostname for
# the srbHost entry and port for srbPort, and then set mdasEnvFile.

	    unlink("SzonesyncMdasEnvFile"); 
	    `cat $UsersEnvFile | grep -v srbHost | grep -v srbPort > SzonesyncMdasEnvFile`; 
	    `echo "srbHost '$host'" >> SzonesyncMdasEnvFile`;
	    if ($port ne "0") {
               `echo "srbPort '$port'" >> SzonesyncMdasEnvFile`;
            }

	    foreach $DO_LIST (@DO_LIST) {
		print $DO_LIST . "\n";

		$ENV{'mdasEnvFile'}="SzonesyncMdasEnvFile"; # to remote MCAT
		runCmd(1, "Spullmeta -F $DO_LIST > $zone.$DO_LIST 2> $zone.Spullmeta.stderr");
		if ($cmdStat ne "0") {
		    $stdErr=`cat $zone.Spullmeta.stderr`;
		    chop($stdErr);
		    print $stdErr;
		    if ($stdErr eq "No Answer") {
			print "\nSpullmeta returned no results ('No Answer'), skipping Spushmeta\n";
		    }
		    else {
			print "Error from Spullmeta, skipping Spushmeta for this item\n";
		    }
		}
		else {
		    delete $ENV{'mdasEnvFile'}; # unset it, back to the local MCAT
		    if ($UsersEnvVar) {
			$ENV{'mdasEnvFile'} = $UsersEnvVar; # back to the user's Env file
		    }
		    runCmd(1, "Spushmeta $zone.$DO_LIST  2>&1 | tee  push.$zone.$DO_LIST");
		    print $cmdOutput;
		}
	    }
	    foreach $DO_LIST_DATED (@DO_LIST_DATED) {
		print $DO_LIST_DATED . " since " . $CHANGED_DATE . "\n";
		$ENV{'mdasEnvFile'}="SzonesyncMdasEnvFile"; # to remote MCAT
		runCmd(1, "Spullmeta -F $DO_LIST_DATED $CHANGED_DATE > $zone.$DO_LIST_DATED 2> $zone.Spullmeta.stderr");
		$doPush=1;
		if ($cmdStat eq "1") {
		    $doPush=0;  # skip the push
		    $stdErr=`cat $zone.Spullmeta.stderr`;
		    chop($stdErr);
		    print $stdErr;
		    if ($stdErr eq "No Answer") {
			print "\nSpullmeta returned no results ('No Answer'), skipping Spushmeta\n";
		    }
		    else {
			print "Error from Spullmeta, skipping Spushmeta for this item\n";
		    }
		}
		if ($doPush eq "1") {
		    # first remove $deleted lines from the pullmeta file,
		    # this is because deleted entries show up this way, and
		    # will get an error if we try to insert them.
		    $del="\\" . "\$deleted";  # $del string = "\$deleted"; 
                          # Both perl and grep treat the $ as special.
                          # Grep gets "\$deleted" and the \ escapes grep's $
		    `grep -v $del $zone.$DO_LIST_DATED > $zone.$DO_LIST_DATED.mod`;

		    delete $ENV{'mdasEnvFile'}; # unset it, back to the local MCAT
		    if ($UsersEnvVar) {
			$ENV{'mdasEnvFile'} = $UsersEnvVar; # back to the user's Env file
		    }
		    runCmd(1, "Spullmeta -F $DO_LIST_DATED $CHANGED_DATE > $zone.$DO_LIST_DATED.orig");
		    runCmd(1, "/usr/bin/python /usr/srb/bin/ZoneUserSync.py $zone.$DO_LIST_DATED.orig  $zone.$DO_LIST_DATED.mod $zone 2>&1 | tee sync.$zone.$DO_LIST_DATED");
		    #runCmd(1, "Spushmeta $zone.$DO_LIST_DATED.mod 2>&1 | tee push.$zone.$DO_LIST_DATED");
		    print $cmdOutput;
		}
	    }
	}
    }
}

# run a command, and exit with a message if there is an error
# if the option is 1, then an exit of 1 is OK 
sub runCmd {
    my($option, $cmd) = @_;
    print "running: $cmd\n";
    $cmdOutput=`$cmd`;
    $cmdStat=$? >> 8;
    if ($cmdStat eq "1" and $option eq "1") {
	return;
    }
    if ($cmdStat!=0) {
	print "The following command failed: $cmd\n";
	print "Exit code= $cmdStat \n";
	die("command failed");
    }
}

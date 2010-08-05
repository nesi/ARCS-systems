#!/usr/bin/env perl
# syncUsers.pl    Decodes the user-list XML file supplied by the ARCS
#                 Access Service, and uses its content to add, modify or
#                 de-activate iRODS users as appropriate.
#                 Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20100805
use strict;
use warnings;
use File::Basename;
use File::Spec;
use Sys::Syslog;
use LWP::UserAgent;       # You may need to do:
use XML::XPath;           # yum install perl-Crypt-SSLeay perl-XML-XPath
use Net::SMTP;
use Sys::Hostname;
use Socket;
use vars qw($VERSION);
$VERSION="2.19";

# Adjust these as appropriate:
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates";
$ENV{HTTPS_CERT_FILE} = "/etc/grid-security/irodscert.pem";
$ENV{HTTPS_KEY_FILE}  = "/etc/grid-security/irodskey.pem";
$ENV{HTTPS_DEBUG} = 0;    # Set to "1" to enable debug
my $URL="https://access.arcs.org.au/service/list.html?serviceId=3";
my $notify="N";           # Set to "Y" to notify users when added

# Log-and-die subroutine
sub log_and_die { # Usage: log_and_die(message)
  syslog("info",$_[0]." "."[pid=".$$."]");
  die($_[0])
}

# Mail-message subroutine
sub mail_mess {  # Usage: mail_mess(address, message)
  if ( defined($_[0]) ) {
    if (my $smtp=Net::SMTP->new("localhost") ) {
      my @host=gethostbyaddr(inet_aton(hostname),AF_INET);
      $smtp->mail($ENV{LOGNAME}."\@".$host[0]); $smtp->to($_[0]);
      $smtp->data("To: ",$_[0],"\nSubject: iRODS User Management",
                               " [mesg-id=".$$."]\n\n".$_[1]);
      $smtp->quit();
      print STDERR "-- Message sent to: ".$_[0]." --\n".$_[1]."--\n"
    }
  }              # Note: Pid is appended to subject to foil
}                # over-enthusiastic spam filters

# Remove-DNs subroutine
sub remove_dn_s { # Usage: remove_dn_s(username)
  foreach my $dnvalue (`iquest "%s" "SELECT USER_DN 
                                     where USER_NAME = '$_[0]'" 2>/dev/null`) {
    chomp($dnvalue);
    my $dnvalueplus="\"".$dnvalue."\"";
    `iadmin rua $_[0] $dnvalueplus >/dev/null 2>&1`
  }
}

# Check usage, check that we can execute 'iadmin', get the current user-list
die "Usage: ".basename($0)." email-addrs\n".
    " e.g.: ".basename($0)." arcs-data\@lists.arcs.org.au\n" if $#ARGV != 0;
`iadmin lu >/dev/null 2>&1`;
log_and_die("Failed to execute 'iadmin lu'") if $?;
my $agent = LWP::UserAgent->new;
my $response = $agent->get($URL);
my $string=$response->content if $response->is_success;

# Decode XML.
my $xp = XML::XPath->new(xml=>$string);
log_and_die("Failed to get XML file") if ! defined($xp);

# Validate the XML by ensuring that we get a complete list of valid usernames
my (@username,@distiname,@sharedtoken,@email);
my $j=0;
foreach my $user ($xp->find('//User')->get_nodelist) {
  $username[++$j] =$user->find('ARCSUserName/@Name')."";
  $distiname[$j]  =$user->find('DistinguishedName/@DN')."";
  $sharedtoken[$j]=$user->find('SharedToken/@Value')."";
  $email[$j]      =$user->find('Email/@Address').""
}                # Note: Stored list elements must be strings for later use
log_and_die("Username list is suspect") if $j < 1;

# Ascertain which version of IRODS we are using, adjust 'moduser' parameters
my ($param1,$param2)=("moduser","DN");
if ( `ienv 2>/dev/null`!~m/rods2.1/ ) { ($param1,$param2)=("aua"    ,""  ) }

# Get the current users and their attributes
my (%user_dn,%user_info,@field,$u);
foreach my $line
  (split ("\n",`yes|iquest "select USER_NAME,USER_DN,USER_INFO" 2>/dev/null`)) {
  if ( $line =~ m/^Continue/ )       { $line=substr($line,15)              }
  @field=split(" ",$line);
  next if ! defined $field[2];
  if    ( $field[0] eq "USER_NAME" ) { 
    $u=$field[2]; $user_info{$u}=$user_dn{$u}=""
  }
  elsif ( $field[0] eq "USER_INFO" ) { $user_info{$u}=$field[2]            }
  elsif ( $field[0] eq "USER_DN"   ) { $user_dn{$u}  =substr($line,10)     }
}

# Add users we don't already have, insert new DN and ST values where necessary
my ($message,$dnplus,$stplus,$oldst);
for (my $k=1;$k<=$j;$k++) {
  $u=$username[$k];
  next if length($u) < 1;
  if ( ! defined $user_info{$u} ) {
    `iadmin mkuser $u rodsuser >/dev/null 2>&1`;
    if ( ! $? ) {
      $user_info{$u}=$user_dn{$u}="";
      $message.="Added user: ".$u."\n";
      if ( ( length($email[$k]) > 0 ) && ( $notify eq "Y" ) ) {
        mail_mess($email[$k],
        "An ARCS-DF user-environment has been created for: ".$u."\n".
        "You can now use the ARCS Data Fabric!\n" )
      }
    }
  } 
  if ( ( ! defined $user_dn{$u} ) || ( $distiname[$k] ne $user_dn{$u} ) ) {
    $dnplus="\"".$distiname[$k]."\"";
    if ( $param1 ne "moduser" ) { remove_dn_s($username[$k]) }
    `iadmin $param1 $username[$k] $param2 $dnplus`;
    if(! $?){$message.="Inserted DN: ".$dnplus." for user: ".$u."\n"}
  }
  $stplus="\"<ST>".$sharedtoken[$k]."</ST>\"";
  if ( (defined($user_info{$u}))&&($stplus ne "\"".$user_info{$u}."\"") ) {
    `iadmin moduser $u info $stplus`;
    if(! $?){$message.="Inserted INFO: ".$stplus." for user: ".$u."\n"}
  }
}

# Remove DNs for unlisted users so they can't do GSI logins
L:foreach my $existing ( `yes|iquest "%s" "SELECT USER_NAME where USER_DN <> ''
          and USER_TYPE = 'rodsuser' and USER_GROUP_NAME <> 'NotPersons'"`) {
  chomp($existing);
  if ( $existing =~ m/^Continue/ )  { $existing=substr($existing,15) }
  for (my $k=1;$k<=$j;$k++) {
    next L if $username[$k] eq $existing;
  }
  $message.="Removing DN(s) for user: ".$existing."\n";
  if ( $param1 eq "moduser" ) { `iadmin moduser $existing DN ""` }
  else                        { remove_dn_s ($existing)          }
}

# Mangle ST records for unlisted users so they can't do Shibboleth logins
M:foreach my $existing( `yes|iquest "%s" "SELECT USER_NAME
       where USER_INFO like '%<ST>%' and USER_GROUP_NAME <> 'NotPersons'"`) {
  chomp($existing);
  if ( $existing =~ m/^Continue/ )  { $existing=substr($existing,15) }
  for (my $k=1;$k<=$j;$k++) {
    next M if $username[$k] eq $existing;
  }
  $oldst=`iquest "%s" "select USER_INFO where USER_NAME = '$existing'"`;
  chomp ($oldst);
  if( $oldst =~ m/<ST>/ ) {
    $oldst =~ s/ST>/st>/g;
    `iadmin moduser $existing info "$oldst"`;
    if(! $?){$message.="Changed INFO for user: ".$existing."  to: ".$oldst."\n"}
  }
}

# Send email and exit
mail_mess($ARGV[0], $message) if defined $message;

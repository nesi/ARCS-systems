#!/usr/bin/env perl
# syncUsers.pl    Decodes the user-list XML file supplied by the ARCS
#                 Access Service, and uses its content to add, modify or
#                 de-activate iRODS users as appropriate.
#                 Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20101125
use strict;
use warnings;             # Interim Version, allows additional APACGrid
use File::Basename;       # or BeSTGRID DN.
use File::Spec;
use Sys::Syslog;
use LWP::UserAgent;       # You may need to do:
use XML::XPath;           # yum install perl-Crypt-SSLeay perl-XML-XPath
use Net::SMTP;
use Sys::Hostname;
use Socket;
use vars qw($VERSION);
$VERSION="2.25";

# Adjust these as appropriate; you may need to comment the next line
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates";
$ENV{HTTPS_CERT_FILE} = "/etc/grid-security/irodscert.pem";
$ENV{HTTPS_KEY_FILE}  = "/etc/grid-security/irodskey.pem";
$ENV{HTTPS_DEBUG} = 0;    # Set to "1" to enable debug
my $URL="https://access.arcs.org.au/service/list.html?serviceId=3";
#my $URL="https://auth14.ac3.edu.au/AccessService/service/list.html?serviceId=3";
my $notify="N";           # Set to "Y" to notify users when added

# Log-and-die subroutine
sub log_and_die { # Usage: log_and_die(message)
  syslog("info",$_[0]." "."[pid=".$$."]");
  die($_[0])
}

# Log-and-continue subroutine
sub log_and_continue { # Usage: log_and_continue(message)
  syslog("info",$_[0]." "."[pid=".$$."]")
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
  my $saved;
  foreach my $dnvalue (`iquest --no-page "%s" "SELECT USER_DN 
                                     where USER_NAME = '$_[0]'" 2>/dev/null`) {
    chomp($dnvalue);
    my $dnvalueplus="\"".$dnvalue."\"";
    # If this is an APACGrid/BeSTGRID DN, save a copy before removing
    if ( ($dnvalue=~m"^/C=AU/O=APACGrid/") ||
         ($dnvalue=~m"^/C=NZ/O=BeSTGRID/")   ) { $saved=$dnvalueplus }
    `iadmin rua $_[0] $dnvalueplus >/dev/null 2>&1`
  }
  # If we saved a DN, put it back; we do it like this because there may be
  # several identical DNs, and 'rua' removes them all
  if( defined ($saved) ) { `iadmin aua $_[0] $saved >/dev/null 2>&1`}
}

# Add-to-Group subroutine
sub add_to_group { # Usage: add_to_group(organisation,username)
  `iadmin mkgroup $_[0] >/dev/null 2>&1`;
  if(! $?) {       # If group doesn't exist, create it and create a its dir'ty
    my $c="iadmin atg               ".$_[0]." rods\n".
          "ichmod own rods       ../".$_[0]."\n".
          "imkdir                ../".$_[0]."/public\n".
          "ichmod read ".$_[0]." ../".$_[0]."\n".
          "ichmod own  ".$_[0]." ../".$_[0]."/public\n".
          "ichmod inherit        ../".$_[0]."/public\n";
    #print "DB1: \n$c \n";
    `( $c ) >/dev/null 2>&1`
  }
  my $ret_stat=0;
  `iadmin atg $_[0] $_[1] >/dev/null 2>&1`;
  if(! $?) {       # If we added the user, create his/her subdirectory
    $ret_stat=1;
    my $c="iadmin atg               ".$_[0]." rods\n".
          "imkdir                ../".$_[0]."/". $_[1]."\n".
          "ichmod own  ".$_[1]." ../".$_[0]."/". $_[1]."\n".
          "ichmod null rods      ../".$_[0]."/". $_[1]."\n".
          "iadmin rfg               ".$_[0]." rods\n";
    #print "DB2: \n$c \n";
    `( $c ) >/dev/null 2>&1`
  }                # If we coudn't add the user, return an error
  return $ret_stat; 
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
my (@username,@distiname,@sharedtoken,@email,@organisation);
my $j=0;
foreach my $user ($xp->find('//User')->get_nodelist) {
  $username[++$j]  =$user->find('ARCSUserName/@Name')."";
  $distiname[$j]   =$user->find('DistinguishedName/@DN')."";
  $sharedtoken[$j] =$user->find('SharedToken/@Value')."";
  $email[$j]       =$user->find('Email/@Address')."";
  $organisation[$j]=$user->find('Organisation/@Value').""
}                # Note: Stored list elements must be strings for later use
log_and_die("Username list is suspect") if $j < 1;

# Get the current users and their attributes
my (%user_dn,%seco_dn,%user_info,%org_group,@field,$u,$message);
foreach my $line
  (split ("\n",`iquest --no-page "select USER_NAME,USER_DN,USER_INFO" 2>/dev/null`)) {
  @field=split(" ",$line);
  next if ! defined $field[2];
  if    ( $field[0] eq "USER_NAME" ) { $u=$field[2]             }
  elsif ( $field[0] eq "USER_INFO" ) { $user_info{$u}=$field[2] }
  elsif ( $field[0] eq "USER_DN"   ) {
    if ( ! defined ($user_dn{$u})  )   { $user_dn{$u}=substr($line,10) }
    else                               { $seco_dn{$u}=substr($line,10) }
  }
}
foreach my $line (`iquest --no-page "%s=%s" "select USER_NAME, USER_GROUP_NAME
                      where USER_GROUP_NAME like 'Organisation %'
                      and USER_NAME not like 'Organisation %'"`) {
  chomp($line);
  @field=split("=",$line);
  if ( defined ($org_group{$field[0]}) ) { 
    my $orgplus="\"".$org_group{$field[0]}."\"";
    $message.="Removing redundant Org'n Group for user: ".$field[0]."\n";
    `iadmin rfg $orgplus $field[0]`
  }
  $org_group{$field[0]}=$field[1]
}

# Add users we don't already have, insert new DN and ST values where necessary
my ($dnplus,$stplus,$oldst,$group);
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
    } else { log_and_continue("Failed to create user: ".$u) }
  } 

  $user_dn{$u}="" if ! defined $user_dn{$u};
  $seco_dn{$u}="" if ! defined $seco_dn{$u};
  if ( ($user_dn{$u} ne $distiname[$k]) && ($seco_dn{$u} ne $distiname[$k]) ) {
    $dnplus="\"".$distiname[$k]."\"";
    remove_dn_s($username[$k]);
    `iadmin aua $username[$k] $dnplus`;
    if(! $?){$message.="Inserted DN: ".$dnplus." for user: ".$u."\n"}
  }
  $stplus="\"<ST>".$sharedtoken[$k]."</ST>\"";
  if ( (defined($user_info{$u}))&&($stplus ne "\"".$user_info{$u}."\"") ) {
    `iadmin moduser $u info $stplus`;
    if(! $?){$message.="Inserted INFO: ".$stplus." for user: ".$u."\n"}
  }
  # Organisation-Group maintenance
  $group="Organisation ".$organisation[$k];
  if ( (defined($org_group{$u}))&&($org_group{$u} ne $group) ) {
    my $orgplus="\"".$org_group{$u}."\"";
    `iadmin rfg $orgplus $u`
  }
  if ( (! defined($org_group{$u})) && (length($organisation[$k])>0) ) {
    if (add_to_group("\"".$group."\"",$u) ) { 
      $message.="Added user: $u to group: $group"."\n"
    }
  }
}

# Remove DNs for unlisted users so they can't do GSI logins
L:foreach my $existing ( `iquest --no-page "%s" "SELECT USER_NAME where USER_DN <> ''
          and USER_TYPE = 'rodsuser' and USER_GROUP_NAME <> 'NotPersons'"`) {
  chomp($existing);
  for (my $k=1;$k<=$j;$k++) {
    next L if $username[$k] eq $existing;
  }
  $message.="Removing DN(s) for user: ".$existing."\n";
  remove_dn_s ($existing)
}

# Mangle ST records for unlisted users so they can't do Shibboleth logins
M:foreach my $existing( `iquest --no-page "%s" "SELECT USER_NAME
       where USER_INFO like '%<ST>%' and USER_GROUP_NAME <> 'NotPersons'"`) {
  chomp($existing);
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

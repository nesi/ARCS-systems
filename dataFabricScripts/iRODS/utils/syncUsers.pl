#!/usr/bin/env perl
# syncUsers.pl    Decodes the user-list XML file supplied by the ARCS
#                 Access Service, and uses its content to add, modify or
#                 de-activate iRODS users as appropriate.
#                 Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20100125
use strict;
use warnings;
use File::Basename;
use File::Spec;
use Sys::Syslog;
use LWP::UserAgent;       # You may need to do:
use XML::XPath;           # yum install perl-Crypt-SSLeay perl-XML-XPath
use Net::SMTP;
use vars qw($VERSION);
$VERSION="2.07";
my $Deactivate="Y";       # Set this to "N" to enable user de-activation

# Adjust these as appropriate:
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates";
$ENV{HTTPS_CERT_FILE} = "/etc/grid-security/irodscert.pem";
$ENV{HTTPS_KEY_FILE}  = "/etc/grid-security/irodskey.pem";
my $URL="https://auth14.ac3.edu.au/AccessService/service/list.html?serviceId=3";

# Log-and-die subroutine
sub log_and_die { # Usage: log_and_die(message)
  syslog("info",$_[0]." "."[pid=".$$."]");
  die($_[0])
}

# Mail-message subroutine
sub mail_mess {  # Usage: mail_mess(address, message)
  if ( defined($_[0]) ) {
    if (my $smtp=Net::SMTP->new("localhost") ) {
      $smtp->mail($ENV{USER}); $smtp->to($_[0]);
      $smtp->data("To: ",$_[0],"\nSubject: iRODS User Management",
                               " [mesg-id=".$$."]\n\n".$_[1]);
      $smtp->quit();
      print STDERR "-- Message sent to: ".$_[0]." --\n".$_[1]."--\n"
    }
  }              # Note: Pid is appended to subject to foil
}                # over-enthusiastic spam filters

# Check usage, check that we can execute 'iadmin', get the current user-list
die "Usage: ".basename($0)." email-addrs\n".
    " e.g.: ".basename($0)." arcs-data\@lists.arcs.org.au\n" if $#ARGV != 0;
`iadmin lu >/dev/null 2>&1`;
log_and_die("Failed to execute 'iadmin lu'") if $?;
my $agent = LWP::UserAgent->new;
my $response = $agent->get($URL);
my $string=$response->content; # if $response->is_success;

# If the checksum on the user-list string hasn't changed, exit; else decode XML.
my $xp;                    # Note that we add a small fraction to the saved sum
if ( defined($string) ) {  # at each fast-exit and compare integer parts of sum
  my $oldsum=-1;           # only; this will eventually force a complete decode.
  my $newsum=unpack("%32C*",$string) % 65535;
  my $savsum=$newsum;
  if ( my @p=getpwnam( $ENV{LOGNAME} ) ) {
    my $sumfile=File::Spec->catdir($p[7],".".basename($0).".sum");
    if ( open( CF,      $sumfile ) ) { $oldsum=<CF>;     close(CF) }
    if ( $newsum == int($oldsum) )   { $savsum=$oldsum + 0.1       }
    if ( open( CF,'+>', $sumfile ) ) { print CF $savsum; close(CF) }
  }
  exit(0) if $newsum == int($oldsum);
  $xp = XML::XPath->new(xml=>$string);
}
log_and_die("Failed to get XML file") if ! defined($xp);

# Validate the XML by ensuring that we get a complete list of valid usernames
my (@username,@distiname,@sharedtoken);
my $j=0;
foreach my $user ($xp->find('//User')->get_nodelist) {
  $username[++$j] =$user->find('ARCSUserName/@Name')."";
  $distiname[$j]  =$user->find('DistinguishedName/@DN')."";
  $sharedtoken[$j]=$user->find('SharedToken/@Value').""
}                # Note: Stored list elements must be strings for later use
log_and_die("Username list is suspect") if $j < 1;

# Add users we don't already have, insert new DN and ST values where necessary
my ($userplus,$olddn,$dnplus,$oldst,$stplus,$message);
for (my $k=1;$k<=$j;$k++) {
  next if length($username[$k]) < 1;
  $userplus="'".$username[$k]."'";
  `iquest "select USER_NAME where USER_NAME = $userplus" >/dev/null 2>&1`;
  if ($?) {
    `iadmin mkuser $username[$k] rodsuser >/dev/null 2>&1`;
    if ( ! $? ) { $message.="Added user: ".$username[$k]."\n" }
    # `/usr/local/bin/createInbox.sh -u $username[$k] >/dev/null 2>&1`;
    # if ( ! $? ) { $message.="Created inbox etc. for: ".$username[$k]."\n" }
  } 
  $olddn=`iquest "select USER_DN where USER_NAME = $userplus" | \
         sed -n "1s/^USER_DN = //p"`;
  chomp ($olddn);
  if ( $distiname[$k] ne $olddn ) {
    $dnplus="\"".$distiname[$k]."\"";
    `iadmin moduser $username[$k] DN $dnplus`;
    if(! $?){$message.="Inserted DN: ".$dnplus." for user: ".$username[$k]."\n"}
  }
  $oldst=`iquest "select USER_INFO where USER_NAME = $userplus" | \
         sed -n "1s/^USER_INFO = //p"`;
  chomp ($oldst);
  if (length($sharedtoken[$k])<1) { $stplus="\"\"" }
  else                            { $stplus="\"<ST>".$sharedtoken[$k]."</ST>\""}
  if ( $stplus ne "\"".$oldst."\"" ) {
    `iadmin moduser $username[$k] info $stplus`;
    if(! $?){$message.="Inserted INFO: ".$stplus." for user: ".$username[$k].
                                                                           "\n"}
  }
}
goto Z unless $Deactivate eq "Y";

# Remove DNs for unlisted users so they can't do GSI logins
L:foreach my $existing (`iquest "SELECT USER_NAME where USER_DN <> ''" | \
                                               awk '{if(NF>2)print \$3}'`) {
  chomp($existing);
  if ( $existing !~ m/^[a-z]+\./ ) { next }
  for (my $k=1;$k<=$j;$k++) {
    next L if $username[$k] eq $existing;
  }
  `iadmin moduser $existing DN ""`;
  if(! $?){$message.="Removed DN for user: ".$existing."\n"}
}

# Mangle ST records for unlisted users so they can't do Shibboleth logins
M:foreach my $existing(`iquest "SELECT USER_NAME where USER_INFO like '%<ST>%'"|
                                               awk '{if(NF>2)print \$3}'`) {
  chomp($existing);
  if ( $existing !~ m/^[a-z]+\./ ) { next }
  for (my $k=1;$k<=$j;$k++) {
    next M if $username[$k] eq $existing;
  }
  $oldst=`iquest "select USER_INFO where USER_NAME = '$existing'" | \
         sed -n "1s/^USER_INFO = //p"`;
  chomp ($oldst);
  if( $oldst =~ m/<ST>/ ) {
    $oldst =~ s/ST>/st>/g;
    `iadmin moduser $existing info "$oldst"`;
    if(! $?){$message.="Changed INFO for user: ".$existing."  to: ".$oldst."\n"}
  }
}

# Send email and exit
Z:mail_mess($ARGV[0], $message) if defined $message;

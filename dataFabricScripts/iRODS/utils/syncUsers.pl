#!/usr/bin/env perl
# syncUsers.pl    Decodes the user-list XML file supplied by the ARCS
#                 Access Service, and uses its content to add, modify or
#                 de-activate iRODS users as appropriate.
#                 Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20100114
use strict;
use warnings;
use File::Basename;
use LWP::Simple;
use Sys::Syslog;
use XML::XPath;           # You may need to do: yum install perl-XML-XPath
use Net::SMTP;
use vars qw($VERSION);
$VERSION="2.04";
my $Deactivate="N";       # Set this to "Y" to enable user de-activation

# Adjust this value as appropriate; should end with '?q=$$' to foil caching
my $URL="http://auth14.ac3.edu.au/AccessService/service/list.html?serviceId=3";

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
my $string=get($URL);
my $xp = XML::XPath->new(xml=>$string) if defined($string); 
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
    `/usr/local/bin/createInbox.sh -u $username[$k] >/dev/null 2>&1`;
    if ( ! $? ) { $message.="Created inbox etc. for: ".$username[$k]."\n" }
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

#!/usr/bin/env perl
# syncUsers.pl    Decodes the user-list XML file supplied by the ARCS
#                 Access Service, and uses its content to add/disable
#                 current iRODS users as appropriate.
#                 Graham Jenkins <graham@vpac.org> Oct. 2009. Rev: 20091026
use strict;
use warnings;
use File::Basename;
use LWP::Simple;
use Sys::Syslog;
use XML::XPath;  # You may need to do: yum install perl-XML-XPath
use Net::SMTP;
use vars qw($VERSION);
$VERSION="1.01";

# Adjust this value as appropriate; should end with '?q=$$' to foil caching
my $URL=
  "https://auth14.ac3.edu.au/AccessService/service/list.html?serviceId=1";

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
my @usernames;
my $j=0;
foreach my $user ($xp->find('//User')->get_nodelist) {
  $usernames[$j++]=$user->find('ARCSUserName/@Name').""
}                # Note: Stored list elements must be strings for later use
log_and_die("Username list is suspect") if $j < 1;

# Add users we don't already have, insert new DN values where necessary
my ($userplus,$olddn,$newdn,$message);
foreach my $user (@usernames) {
   $userplus="'".$user."'";
  `iquest "select USER_NAME where USER_NAME = $userplus" >/dev/null 2>&1`;
   if ($?) {
     `iadmin mkuser $user rodsuser >/dev/null 2>&1`;
     if ( ! $? ) { $message="Added user: ".$user."\n" }
   } 
  $olddn=`iquest "SELECT USER_DN where USER_NAME = $userplus" | \
          awk '{print \$3;exit}'`;
  chomp ($olddn);
  $newdn=$user."\@ARCS.ORG.AU";
  if ( $newdn ne $olddn ) {
    `iadmin moduser $user DN $newdn`;
     if ( ! $? ) { $message.="Inserted DN: ".$newdn." for user: ".$user."\n" }
  }
}

# Disable iRODS usage by those active users not in the current-user list
L1: foreach my $existing (`iquest "SELECT USER_NAME where USER_DN <> ''" | \
                                               awk '{if(NF>1)print \$3}'`) {
  chomp($existing);
  foreach my $user (@usernames) {
    next L1 if $user eq $existing;
  }              # Note: Delete 'echo ' in following line after debugging!
  `echo iadmin moduser $existing DN ""`;
  if ( ! $? ) { $message.="Disabled user: ".$existing."\n" }
}

# Send email and exit
mail_mess($ARGV[0], $message) if defined $message;

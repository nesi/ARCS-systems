#!/usr/bin/perl

use SOAP::Lite;
use Cwd;
use XML::DOM;

require RPC::XML;
require RPC::XML::Client;

my $cwd = getcwd();
#print "file://".$cwd."/IncaWS.wsdl\n";
my $ws = SOAP::Lite->service("file:".$cwd."/IncaWS.wsdl"); #inca-2.3/Inca-WS-2.10611/etc/IncaWS.wsdl"); #$cwd/etc/IncaWS.wsdl");

# check agent and depot are available
#print $ws->pingAgent('hello agent'), "\n";
#print $ws->pingDepot('hello depot'), "\n";

# get the Inca configuration
#print $ws->getConfig(), "\n";
my $guid = $ws->queryGuids();

#print $guid, "\n";

my $parser = new XML::DOM::Parser;
my $doc;
my $nodeList;
my $srbHost;
my $errorMessage;
my %results = ();
my $result;
my %info =();
for my $testid ( split(/\n/,$guid) ){
#  print $testid, "\n";
  if ($testid =~/srb_test/) {
#    print "found SRB Test\n";
    my $results = $ws->querySuite ($testid);
    for my $result ( @{$results} ) {
#      print "PRINTING RESULT:".">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
#      print $result."\n";
      $doc = $parser->parse ($result);
      $nodeList = $doc->getElementsByTagName("srb_host");
#      print $nodeList->getLength."\n";
      if ($nodeList->getLength > 0){
      $srbHost = $nodeList->item(0)->getFirstChild->getNodeValue;
#      print $nodeList->getLength."\n";
#      print "SRB Host: ".$srbHost."\n";
      $nodeList = $doc->getElementsByTagName("errorMessage");
#      print $nodeList->getLength."\n";
#      print $nodeList->item(0)->getFirstChild."\n";
      $errorMessage = "";
      if ($nodeList->item(0)->getFirstChild != None) {
	$errorMessage = $nodeList->item(0)->getFirstChild->getNodeValue;
      }
#      print $errorMessage."\n";
      if (exists($results{$srbHost})){
	$result=$results{$srbHost};
      }
      else
      {
	$result=0;
      }
#      print "get result $result for $srbHost before checking\n";
      if ($errorMessage eq ""){
	$result = $result | 2;
#	print "no error($result)\n";
      }else{
	$result = $result | 1;
	$info{$srbHost}=$errorMessage;
#	print "found error($result)\n";
      }
      $results{$srbHost}=$result;
      }
    }
  }
}
# get the latest instances of a suite
#my $results = $ws->querySuite( $guid );
#for my $result ( @{$results} ) {
#  print "PRINTING RESULT:"."\n";
#  print $result;
#}

my $cli = RPC::XML::Client->new('http://status.arcs.org.au/xmlrpc/');
if ($ENV{"http_proxy"}) {
  my $http_proxy=$ENV{"http_proxy"};
  $cli->useragent->proxy(['http', 'ftp'] => "$http_proxy");
}
#my $resp = $cli->send_request('system.listMethods');
#for my $method ( @{$resp} ) {
#  print $$method."\n";
#}
#print $resp."\n";

my $return_code;
while (($key, $value) = each %results){
  if ($value==2){
    $return_code=$cli->send_request('send_inca_status',"$key",2,"");
  } elsif ($value==1){
    $return_code=$cli->send_request('send_inca_status',"$key",-1,"$info{$key}");
  } elsif ($value==3){
    $return_code=$cli->send_request('send_inca_status',"$key",1,"$info{$key}");
  }
  print "sent $key with status $value, return code is $$return_code.\n";
}


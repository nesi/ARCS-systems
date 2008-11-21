#!/usr/bin/env python

# A sample of createing federation
#Singesttoken Domain srb.hpcu.uq.edu.au home
#Singestuser srbAdmin wabkusbdkweu srb.hpcu.uq.edu.au sysadmin '' '' '' ENCRPYT1 ''
#Sregisterlocation srb.hpcu.uq.edu.au ngsrb.hpcu.uq.edu.au home srbAdmin srb.hpcu.uq.edu.au
#Szone -r srb.hpcu.uq.edu.au srb.hpcu.uq.edu.au 5544 srbAdmin@srb.hpcu.uq.edu.au '' ''
#SmodifyUser changeZone srbAdmin srb.hpcu.uq.edu.au srb.hpcu.uq.edu.au

from xml.dom import minidom
import sys,traceback
import urllib2
import commands
import string

def find_zone(doc,site_name,svr_type):
    for zone in doc.getElementsByTagName("srb-servers"):
        if string.lower(str(zone.getAttribute("site"))) == string.lower(site_name):
            for srb_svr in zone.getElementsByTagName("srb"):
		if string.lower(srb_svr.getAttribute(str("type"))) == string.lower(svr_type):
		    return srb_svr

def find_domain(domains):
    for domain in domains:
        if string.lower(str(domain.getAttribute("primary"))) == "yes":
	    return domain

def run_cmd(cmd):
    print "Executing: "+cmd
    result=commands.getstatusoutput(cmd)
    if result[0] != 0:
	print result[1]
    return result[0]

def federate(site_name,svr_type):
#    if os.environ.has_key("http_proxy"):
#        my_http_proxy=os.environ["http_proxy"].replace("http://","")
#    else:
#        my_http_proxy=None
    xml_url="http://projects.arcs.org.au/trac/systems/browser/trunk/data-services/"+site_name+".xml?format=raw"
    try:
        response = urllib2.urlopen(xml_url)
    except Exception,inst:
        print "There is no such site information."
        return 1
    xml_content=response.read()
#    print xml_content
    doc = minidom.parseString(xml_content).documentElement
    srb_zone = find_zone(doc,site_name,svr_type)
    if srb_zone is None:
	print "Zone or server type does not exist!"
	return 1
    host=srb_zone.getElementsByTagName("host")[0]
    if host is None:
	print "No host is found!"
	return 1
    zone_name=srb_zone.getElementsByTagName("zone-name")[0].childNodes[0].nodeValue
    cname=host.getElementsByTagName("friendly-name")[0].childNodes[0].nodeValue
    hostname=host.getElementsByTagName("host-name")[0].childNodes[0].nodeValue
    domain=find_domain(srb_zone.getElementsByTagName("domain"))
    if domain is None:
	print "Domain is not found!"
	return 1
    domain_name=domain.getElementsByTagName("domain-name")[0].childNodes[0].nodeValue

#    print host.getElementsByTagName("host-name")[0]
    if hostname is None:
	print "Cannot find hostname!"
	return 1
    if cname is None:
	cname = hostname
    if run_cmd("Sinit")!=0:
	print "Cannot initiate SRB session."
	return 1
    run_cmd("Singesttoken Domain "+domain_name+" home")
    run_cmd("Singestuser srbAdmin wabkusbdkweu "+domain_name+" sysadmin '' '' '' ENCRPYT1 ''")
    run_cmd("Sregisterlocation "+cname+" "+hostname+" home srbAdmin "+domain_name)
    run_cmd("Szone -r "+zone_name+" "+cname+" 5544 srbAdmin@"+domain_name+" '' ''")
    run_cmd("SmodifyUser changeZone srbAdmin "+domain_name+" "+domain_name)
    print "Federation with "+site_name+" is created. Please run 'Szonesync.pl -u' after "+site_name+" creates federation with you."
    return 0

def main():
#    print len(sys.argv)
    svr_type="production"
    if len(sys.argv) < 2:
        print "Syntax: "+sys.argv[0]+" <site name> [type]"
        print "       type: production or development, default is production"
        return 1
    if len(sys.argv) >2:
        svr_type=sys.argv[2]
    return federate(sys.argv[1],svr_type)




if __name__ == "__main__": sys.exit(main())


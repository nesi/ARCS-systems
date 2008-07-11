#!/usr/bin/env python

# A sample of .MdasEnv file
#mdasCollectionHome '/srb.sapac.edu.au/home/shunde.srb.sapac.edu.au'
#mdasDomainName 'srb.sapac.edu.au'
#srbUser 'shunde'
#srbHost 'srb.sapac.edu.au'
#srbPort '5544'
#defaultResource 'datafabric.srb.sapac.edu.au'
#AUTH_SCHEME 'GSI_AUTH'
##AUTH_SCHEME 'ENCRYPT1'
#SERVER_DN '/C=AU/O=APACGrid/OU=SAPAC/CN=srb.sapac.edu.au'

from xml.dom import minidom
import sys,traceback
import urllib2
import commands
import string
import os

def find_zone(doc,site_name,svr_type):
    for zone in doc.getElementsByTagName("srb-servers"):
        if string.lower(str(zone.getAttribute("site"))) == string.lower(site_name):
            for srb_svr in zone.getElementsByTagName("srb"):
		if string.lower(srb_svr.getAttribute(str("type"))) == string.lower(svr_type):
		    return srb_svr

def run_cmd(cmd):
    print "Executing: "+cmd
    result=commands.getstatusoutput(cmd)
    if result[0] != 0:
	print result[1]
	return result[0]

def makeenv(site_name,svr_type,output_file):
    srb_env = []
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
    zone_name=srb_zone.getElementsByTagName("zone-name")[0].childNodes[0].nodeValue
    if zone_name is None:
	print "cannot find zone name!"
	return 1
    host=srb_zone.getElementsByTagName("host")[0]
    if host is None:
	print "No host is found!"
	return 1
    cname=host.getElementsByTagName("friendly-name")[0].childNodes[0].nodeValue
    hostname=host.getElementsByTagName("host-name")[0].childNodes[0].nodeValue
    port_num=host.getElementsByTagName("port-number")[0].childNodes[0].nodeValue
    for auth in host.getElementsByTagName("auth-scheme"):
	if auth.childNodes[0].nodeValue=="GSI":
	    server_dn=auth.attributes["dn"].value
    if server_dn is None:
        print "Cannot find srb server DN!"
        return 1
#    print host.getElementsByTagName("host-name")[0]
    if cname is None:
	cname = hostname
    if cname is None:
        print "Cannot find srb host!"
        return 1
    for domain in srb_zone.getElementsByTagName("domain"):
	if domain.attributes["primary"].value=="yes":
	    domain_name=domain.getElementsByTagName("domain-name")[0].childNodes[0].nodeValue
	    domain_test_user=domain.getElementsByTagName("domain-test-user")[0].childNodes[0].nodeValue
    if domain_name is None:
        print "cannot find domain name!"
        return 1
    if domain_test_user is None:
        print "cannot find domain test user!"
        return 1
    for res in srb_zone.getElementsByTagName("resource"):
        if domain.attributes["primary"].value=="yes":
            default_res=res.getElementsByTagName("resource-name")[0].childNodes[0].nodeValue
    if default_res is None:
        print "cannot find default resource!"
        return 1
    srb_env.append("mdasCollectionHome '/"+zone_name+"/home/"+domain_test_user+"."+domain_name+"'")
    srb_env.append("mdasDomainName '"+domain_name+"'")
    srb_env.append("srbUser '"+domain_test_user+"'")
    srb_env.append("srbHost '"+cname+"'")
    srb_env.append("srbPort '"+port_num+"'")
    srb_env.append("defaultResource '"+default_res+"'")
    srb_env.append("AUTH_SCHEME 'GSI_AUTH'")
    srb_env.append("SERVER_DN '"+server_dn+"'")
#    print srb_env
    if output_file is None:
	print os.getenv("HOME")
        if os.path.exists(os.getenv("HOME")+"/.srb/.MdasEnv"):
	    os.rename(os.getenv("HOME")+"/.srb/.MdasEnv",os.getenv("HOME")+"/.srb/.MdasEnv.inca.test.bak")
	output_file=os.getenv("HOME")+"/.srb/.MdasEnv"
    FILE = open(output_file,"w")
    for line in srb_env:
    	FILE.write(line+"\n")
    FILE.close() 
    return 0

def restore():
    if os.path.exists(os.getenv("HOME")+"/.srb/.MdasEnv.inca.test.bak"):
	os.remove(os.getenv("HOME")+"/.srb/.MdasEnv")
	os.rename(os.getenv("HOME")+"/.srb/.MdasEnv.inca.test.bak",os.getenv("HOME")+"/.srb/.MdasEnv")
    return 0

def main():
#    print len(sys.argv)
    svr_type="production"
#    print cmp(sys.argv[1],"-m")
    if len(sys.argv) < 3 or (cmp(sys.argv[1],"-m")!=0 and cmp(sys.argv[1],"-r")!=0):
        print "Syntax: "+sys.argv[0]+" <option> <site name> [type] [-o outputfilename]"
	print "       option: -m make a new srb env file, backup the existing one"
	print "               -r restore the backup env file"
        print "       type: production or development, default is production"
        return 1
    if len(sys.argv) >3:
	if sys.argv[3]=="-o":
	    outputfile=sys.argv[4]
	if sys.argv[4]=="-o":
            svr_type=sys.argv[3]
	    outputfile=sys.argv[5]
    if sys.argv[1]=="-m":
	return makeenv(sys.argv[2],svr_type,outputfile)
    if sys.argv[1]=="-r":
	return restore()




if __name__ == "__main__": sys.exit(main())



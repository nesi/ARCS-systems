#!/usr/bin/env python

from SOAPpy import SOAPProxy
from xml.dom import minidom
import os
import sys
import commands
import time

xml_file=os.path.dirname(os.path.abspath(sys.argv[0]))+"/fc-config.xml"


#def get_url(lfn, url):


def test_fc(fc_name):
    if os.environ.has_key("http_proxy"):
	my_http_proxy=os.environ["http_proxy"].replace("http://","")
    else:
	my_http_proxy=None
    doc = minidom.parse(xml_file)
    ns   = 'urn:fc.ildg.lqcd.org'
    for fc_test in doc.documentElement.getElementsByTagName("fc"):
        grid_name=fc_test.getElementsByTagName("name")[0].childNodes[0].nodeValue
        fc_url=fc_test.getElementsByTagName("url")[0].childNodes[0].nodeValue
        if grid_name == fc_name:
	    try:
		server = SOAPProxy(fc_url, namespace=ns, http_proxy=my_http_proxy)
		for test_unit in fc_test.getElementsByTagName("test-unit"):
		    lfn=test_unit.getElementsByTagName("lfn")[0].childNodes[0].nodeValue
		    response=server.getURL(lfnList=lfn)
		    val_test=True
		    for val in test_unit.getElementsByTagName("surl"):
			val_test=val_test and val.childNodes[0].nodeValue in response.resultList[0].surlList
			print '==',val.childNodes[0].nodeValue
			print val.childNodes[0].nodeValue in response.resultList[0].surlList
		    print test_unit.getElementsByTagName("surl").length
#		print response
#		print response.resultList
#		print response.resultList[0].surlList
#		    print len(response.resultList[0].surlList)
#		    for item in response.resultList[0].surlList:
#			print '--',item
#		    print val_test
		    if val_test==True: return 0
                    return 1
	    except Exception,inst:
		print inst
		return -1



def main():
#    print len(sys.argv)
    if len(sys.argv) < 2:
        print "Syntax: "+sys.argv[0]+" <Grid name>"
        return 2
    return test_fc(sys.argv[1])




if __name__ == "__main__": sys.exit(main())


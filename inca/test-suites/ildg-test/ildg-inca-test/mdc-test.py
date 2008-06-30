#!/usr/bin/env python

#from MDCService_services import *
from SOAPpy import SOAPProxy
from xml.dom import minidom
import os
import sys,traceback
import commands
import time

xml_file=os.path.dirname(os.path.abspath(sys.argv[0]))+"/mdc-config.xml"

return_code=0
output_str=[]
for i in range(0,16):
    output_str.append("")
test_results=[]
for i in range(0,16):
    test_results.append(True)

def verify(num, test_string, test_result):
    global return_code
    global output_str
    global test_results
#    print num,test_result
    output_str[num]=output_str[num]+str(num)+')'+test_string+" "+str(test_result)+"\n"
    test_results[num]=test_results[num] and test_result
    if test_result == False:
	print str(num)+')', test_string, 'Failed!'
#	print "---",return_code
	return_code=1
#	print "---",return_code

def show_err(num, info, response_str):
    if test_results[num] == False:
	sys.stderr.write(info)
	sys.stderr.write(response_str)
	sys.stderr.write(output_str[num])
    else:
	sys.stderr.write(output_str[num])


def do_test(server):

#=============================================================================================================
# Configuration metadata
#=============================================================================================================

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #1
# =======
# Get the first 10 configuration LFNs from the catalogue
#
# Input:
# Operation:            doConfigurationLFNQuery
# Xpath query used:     /gaugeConfiguration
# startIndex:           0
# maxResults:           10
#
'''
    data_lfn=""
    n_config=-1
    try:
    	query_format='Xpath'
	query_string='/gaugeConfiguration'
    	start_index=0
    	max_result=10
    	response=server.doConfigurationLFNQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
	    nresults =0 
    	else: 
	    nresults = len(response.results)
#    	sys.stderr.write("nresults: "+str(nresults)+"\n")
    	if response.totalResults>10:
	    n= 10 
    	else: 
	    n= response.totalResults
    	verify(1, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(1, "queryTime non-empty string", response.queryTime != "")
    	verify(1, "startIndex == "+str(start_index), response.startIndex == start_index)
    	verify(1, "numberOfResults > 0", response.numberOfResults > 0)
    	verify(1, "numberOfResults <= "+str(n), response.numberOfResults <= n)
    	verify(1, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(1, "totalResults > 0", response.totalResults > 0)
    	verify(1, "#results == numberOfResults", nresults == response.numberOfResults)
        show_err(1, test_info, "response: "+str(response)+"\n")

	if response.results is None:
	    data_lfn=""
	else:
    	    data_lfn = response.results[0]
    	n_config = response.totalResults

    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #2
# =======
# Get all configuration LFNs from the catalogue
#
# Input:
# Operation:            doConfigurationLFNQuery
# Xpath query used:     /gaugeConfiguration
# StartIndex:           0
# MaxResults:           -1
#
'''
    try:
    	query_format='Xpath'
    	query_string='/gaugeConfiguration'
    	start_index=0
    	max_result=-1
    	response=server.doConfigurationLFNQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
#        sys.stderr.write("nresults: "+str(nresults)+"\n")
    	verify(2, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(2, "queryTime non-empty string", response.queryTime != "")
    	verify(2, "startIndex == "+str(start_index), response.startIndex == start_index)
    	verify(2, "numberOfResults >= 0", response.numberOfResults >= 0)
    	verify(2, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(2, "totalResults >= 0", response.totalResults >= 0)
    	verify(2, "#results == numberOfResults", nresults == response.numberOfResults)
        show_err(2, test_info, "nresults: "+str(nresults)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #3
# =======
# Query for configurations where the result does not exist
#
# Input:
# Operation:            doConfigurationLFNQuery
# Xpath query used:     /gaugeConfiguration[//dataLFN='NO_SUCH_LFN']
# StartIndex:           0
# MaxResults:           10
#
'''
    try:
    	query_format='Xpath'
    	query_string='/gaugeConfiguration/markovStepr[dataLFN=\'NO_SUCH_LFN\']'
    	start_index=0
    	max_result=10
    	response=server.doConfigurationLFNQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")

    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)

    	verify(3, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(3, "queryTime non-empty string", response.queryTime != "")
    	verify(3, "startIndex == 0", response.startIndex == 0)
    	verify(3, "numberOfResults == 0", response.numberOfResults == 0)
    	verify(3, "totalResults == 0", response.totalResults == 0)
    	verify(3, "#results == 0", nresults == 0)
	show_err(3, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #4
# =======
# Test what happens when syntactically invalid Xpath is submitted
#
# Input:
# Operation:            doConfigurationLFNQuery
# Xpath query used:     #$&^*(or anything else invalid)
# startIndex:           0
# maxResults:           10
#
'''
    try:
    	query_format='Xpath'
    	query_string='#$&^*'
    	start_index=0
    	max_result=10
    	response=server.doConfigurationLFNQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")

    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
	
    	verify(4, "statusCode equal MDC_INVALID_REQUEST or MDC_FAILURE", response.statusCode == "MDC_INVALID_REQUEST" or response.statusCode == "MDC_FAILURE")
    	verify(4, "queryTime non-empty string", response.queryTime != "")
    	verify(4, "startIndex == 0", response.startIndex == 0)
    	verify(4, "numberOfResults == 0", response.numberOfResults == 0)
    	verify(4, "totalResults == 0", response.totalResults == 0)
    	verify(4, "#results == 0", nresults == 0)
	show_err(4, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst


    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #5
# =======
# Retrieve metadata from catalogue
#
# Input:
# Operation:            getConfigurationMetadata
# LFN used:             Select LFN from test #1
#
'''
    try:
    	lfn  = data_lfn

    	response=server.getConfigurationMetadata(lfn)
#    	sys.stderr.write("response: "+str(response)+"\n")

#    print response.document
    	strlen = len(response.document)


    	verify(5, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(5, "document non-empty string", strlen != 0)
	show_err(5, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst


    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #6
# =======
# Attempt to retrieve non-existing metadata from the catalogue
#
# Input:
# Operation:            getConfigurationMetadata
# LFN used:             NO_SUCH_LFN
#
'''
    try:
    	lfn  = "NO_SUCH_LFN"

    	response=server.getConfigurationMetadata(lfn)
#    	sys.stderr.write("response: "+str(response)+"\n")

    	if response.document is None:
	    strlen=0
    	else:
	    strlen = len(response.document)

    	verify(6, "statusCode equal MDC_NO_DATA", response.statusCode == "MDC_NO_DATA")
    	verify(6, "document empty string", strlen == 0)
	show_err(6, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #7
# =======
# Attempt to retrieve a subset of all query matches
#
# Input:
# Operation:            doConfigurationLFNQuery
# Xpath query used:     /gaugeConfiguration
# startIndex:           1
# maxResults:           3
#
# Comment: We assume no document has been deleted since test #1 has been executed
'''
    try:
    	query_string  = "/gaugeConfiguration";
    	if (n_config >= 2):
	    start_index=1
    	else:
	    start_index=0

    	if (n_config >= 3):
            max_results=3
    	else:
            max_results=1

    	response=server.doConfigurationLFNQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
            nresults =0
    	else:
            nresults = len(response.results)
#    	sys.stderr.write("nresults: "+str(nresults)+"\n")
    	if response.totalResults>10:
            n= 10
    	else:
            n= response.totalResults

    	verify(7, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(7, "queryTime non-empty string", response.queryTime != "")
    	verify(7, "startIndex == $startIndex", response.startIndex == start_index)
    	verify(7, "numberOfResults > 0", response.numberOfResults > 0)
    	verify(7, "numberOfResults <= "+str(n), response.numberOfResults <= n)
    	verify(7, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(7, "totalResults > 0", response.totalResults > 0)
    	verify(7, "#results == numberOfResults", nresults == response.numberOfResults)
	show_err(7, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst



#=============================================================================================================
# Ensemble metadata
#=============================================================================================================
    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #8
# =======
# Get the first 10 ensemble URIs from the catalogue
#
# Input:
# Operation:            doEnsembleURIQuery
# Xpath query used:     /markovChain
# startIndex:           0
# maxResults:           10
#
'''
    try:
    	query_string = "/markovChain"
    	start_index = 0
    	max_results = 10

    	response = server.doEnsembleURIQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
#    	sys.stderr.write("nresults: "+str(nresults)+"\n")
    	if response.totalResults>10:
    	    n= 10
    	else:
    	    n= response.totalResults

    	verify(8, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(8, "queryTime non-empty string", response.queryTime != "")
    	verify(8, "startIndex == "+str(start_index), response.startIndex == start_index)
    	verify(8, "numberOfResults > 0", response.numberOfResults > 0)
    	verify(8, "numberOfResults <= "+str(n), response.numberOfResults <= n)
    	verify(8, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(8, "totalResults > 0", response.totalResults > 0)
    	verify(8, "#results == numberOfResults", nresults == response.numberOfResults)
	show_err(8, test_info, "response: "+str(response)+"\n")

    	ensembleURI = response.results[0]
    	nEnsemble   = response.totalResults
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst


    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #9
# =======
# Get all ensemble URIs from the catalogue
#
# Input:
# Operation:            doEnsembleURIQuery
# Xpath query used:     /markovChain
# startIndex:           0
# maxResults:           -1
#
'''
    try:
    	query_string      = "/markovChain"
    	start_index = 0
    	max_results = -1
    	response = server.doEnsembleURIQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
#    	sys.stderr.write("nresults: "+str(nresults)+"\n")

    	verify(9, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(9, "queryTime non-empty string", response.queryTime != "")
    	verify(9, "startIndex == "+str(start_index), response.startIndex == start_index)
    	verify(9, "numberOfResults > 0", response.numberOfResults > 0)
    	verify(9, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(9, "totalResults > 0", response.totalResults > 0)
    	verify(9, "#results == numberOfResults", nresults == response.numberOfResults)
	show_err(9, test_info, "nresults: "+str(nresults)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #10
# ========
# Query for ensembles where the result does not exist
#
# Input:
# Operation:            doEnsembleURIQuery
# Xpath query used:     /markovChain[//markovChainURI='NO_SUCH_URI']
# startIndex:           0
# maxResults:           10
#
'''
    try:
    	query_string      = "/markovChain[//markoChainURI='NO_SUCH_URI']"
    	start_index = 0
    	max_results = 10
    	response = server.doEnsembleURIQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
	
	verify(10, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(10, "queryTime non-empty string", response.queryTime != "")
    	verify(10, "startIndex == 0", response.startIndex == 0)
    	verify(10, "numberOfResults == 0", response.numberOfResults == 0)
    	verify(10, "totalResults == 0", response.totalResults == 0)
    	verify(10, "#results == 0", nresults == 0)
	show_err(10, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #11
# ========
# Test what happens when syntactically invalid Xpath is submitted
#
# Input
# =====
# Operation:            doEnsembleURIQuery
# Xpath query used:     #$&^*(or anything else invalid)
# startIndex:           0
# maxResults:           10
#
'''
    try:
    	query_string      = "#$&^*"
    	start_index = 0
    	max_results = 10
    	response = server.doEnsembleURIQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)

    	verify(11, "statusCode equal MDC_INVALID_REQUEST or MDC_FAILURE", response.statusCode == "MDC_INVALID_REQUEST" or response.statusCode == "MDC_FAILURE")
    	verify(11, "queryTime non-empty string", response.queryTime != "")
    	verify(11, "startIndex == 0", response.startIndex == 0)
    	verify(11, "numberOfResults == 0", response.numberOfResults == 0)
    	verify(11, "totalResults == 0", response.totalResults == 0)
    	verify(11, "#results == 0", nresults == 0)
	show_err(11, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #12
# ========
# Retrieve metadata from catalogue
#
# Input:
# Operation:            getEnsembleMetadata
# LFN used:             Select URI from previous test
#
'''
    try:
    	uri  = ensembleURI

    	response = server.getEnsembleMetadata(uri)
#	sys.stderr.write("response: "+str(response)+"\n")

    	strlen = len(response.document)

    	verify(12, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(12, "document non-empty string", strlen != 0)
	show_err(12, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #13
# ========
# Attempt to retrieve non-existing metadata from the catalogue
#
# Input:
# Operation:            getEnsembleMetadata
# LFN used:             NO_SUCH_URI
#
'''
    try:
    	uri  = "NO_SUCH_URI"

    	response = server.getEnsembleMetadata(uri)
#	sys.stderr.write("response: "+str(response)+"\n")
    	if response.document is None:
	    strlen=0
    	else:    
	    strlen = len(response.document)

    	verify(13, "statusCode equal MDC_NO_DATA", response.statusCode == "MDC_NO_DATA")
    	verify(13, "document empty string", strlen == 0)
	show_err(13, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #14
# ========
# Attempt to retrieve a subset of all query matches
#
# Input:
# Operation:            doEnsembleURIQuery
# Xpath query used:     /markovChain
# startIndex:           1
# maxResults:           3
#
# Comment: We assume no document has been deleted since test #1 has been executed
'''
    try:
    	query_string      = "/markovChain";
    	if (n_config >= 2):
    	    start_index=1
    	else:
    	    start_index=0

    	if (n_config >= 3):
    	    max_results=3
    	else:
    	    max_results=1

    	response = server.doEnsembleURIQuery(queryFormat=query_format,queryString=query_string,startIndex=start_index,maxResults=max_result)
#    	sys.stderr.write("response: "+str(response)+"\n")
    	if response.results is None:
    	    nresults =0
    	else:
    	    nresults = len(response.results)
#    	sys.stderr.write("nresults: "+str(nresults)+"\n")
    	if response.totalResults>10:
    	    n= 10
    	else:
    	    n= response.totalResults

    	verify(14, "statusCode equal MDC_SUCCESS", response.statusCode == "MDC_SUCCESS")
    	verify(14, "queryTime non-empty string", response.queryTime != "")
    	verify(14, "startIndex == "+str(start_index), response.startIndex == start_index)
    	verify(14, "numberOfResults > 0", response.numberOfResults > 0)
    	verify(14, "numberOfResults <= "+str(n), response.numberOfResults <= n)
    	verify(14, "numberofResults <= totalResults", response.numberOfResults <= response.totalResults)
    	verify(14, "totalResults > 0", response.totalResults > 0)
    	verify(14, "#results == numberOfResults", nresults == response.numberOfResults)
	show_err(14, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst

    test_info='''
#-------------------------------------------------------------------------------------------------------------
# Test #15
# ========
# Get MDC information
#
# Input:
# Operation:            getMDCinfo
#
'''
    try:
    	response = server.getMDCinfo()
#    	sys.stderr.write("response: "+str(response)+"\n")

    	query_types = response.queryTypes
    	verify(15, "groupName non-empty string", len(response.groupName)  != 0)
    	verify(15, "groupURL non-empty string", len(response.groupURL)  != 0)
    	verify(15, "queryTypes non-empty list", len(query_types)  != 0)
    	verify(15, "queryTypes includes \"Xpath\"", "Xpath" in query_types)
    	verify(15, "version non-empty string", len(response.version) != 0)
	show_err(15, test_info, "response: "+str(response)+"\n")
    except Exception,inst:
        traceback.print_exc(file=sys.stderr)
        print inst



def test_mdc(mdc_name):
    if os.environ.has_key("http_proxy"):
        my_http_proxy=os.environ["http_proxy"].replace("http://","")
    else:
        my_http_proxy=None

    doc = minidom.parse(xml_file)
    ns = 'urn:fc.ildg.lqcd.org'
    for mdc_test in doc.documentElement.getElementsByTagName("mdc"):
        grid_name=mdc_test.getElementsByTagName("name")[0].childNodes[0].nodeValue
        mdc_url=mdc_test.getElementsByTagName("url")[0].childNodes[0].nodeValue
        if grid_name == mdc_name:
	    try:
		server = SOAPProxy(mdc_url, namespace=ns, http_proxy=my_http_proxy)
		do_test(server)
#		print "return code:",return_code
		return return_code
	    except Exception,inst:
		traceback.print_exc(file=sys.stderr)
#		print inst
        	return -1



def main():
#    print len(sys.argv)
    if len(sys.argv) < 2:
        print "Syntax: "+sys.argv[0]+" <Grid name>"
        return 2
    return test_mdc(sys.argv[1])




if __name__ == "__main__": sys.exit(main())


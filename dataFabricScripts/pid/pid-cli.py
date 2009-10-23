#!/usr/bin/python

import httplib,sys
import getopt,getpass
import urllib
from xml.dom import minidom

request_body='<request name="mint"><properties><property name="appId" value="715a3f79b5c9e8a02a6dee9231af67c2868e80f8"/><property name="identifier" value="shunde"/><property name="authDomain" value="arcsdev.df.arcs.org.au"/></properties></request>'
domain="df.arcs.org.au"
identifier=getpass.getuser()
app_id="715a3f79b5c9e8a02a6dee9231af67c2868e80f8"
service_url="test.ands.org.au:8443"
verbose = False

def construct_request_body():
  global domain,identifier,app_id
  request_body='<request name="mint"><properties><property name="appId" value="'+app_id+'"/>'
  request_body+='<property name="identifier" value="'+identifier+'"/>'
  request_body+='<property name="authDomain" value="'+domain+'"/></properties></request>'
  return request_body

def send_request(uri):
  try:
    conn = httplib.HTTPSConnection(service_url)
    if verbose == True:
      conn.set_debuglevel(9)
#      print request_body
    conn.request("POST", uri, construct_request_body())
    r1 = conn.getresponse()
#    print r1.status, r1.reason
    data = r1.read()
    if verbose == True:
      print urllib.unquote(data)
    conn.close()
    return urllib.unquote(data)
  except httplib.HTTPException, e:
    print "HTTP error: %d" % e.code
    print e
    print e.args
    print "Network error: %s" % e.reason.args[1]


def create_handle(url):
  uri="/pids/mint?type=URL&value="+urllib.quote_plus(url)
  result=send_request(uri)
  doc=minidom.parseString(result)
  response=doc.documentElement
#  print response.getAttribute("type")
#  print cmp(response.getAttribute("type"),"success")
  if cmp(response.getAttribute("type"),"success")==0:
    identifier=response.getElementsByTagName("identifier")[0]
#      print ident
    print identifier.getAttribute("handle")
    sys.exit()
  else:
     print response.getElementsByTagName("message")[0].childNodes[0].nodeValue
     sys.exit(1)



def list_handles():
  uri="/pids/listHandles"
  result=send_request(uri)
  doc=minidom.parseString(result)
#  print doc.documentElement
  response=doc.documentElement
#  print response.getAttribute("type")
#  print cmp(response.getAttribute("type"),"success")
  if cmp(response.getAttribute("type"),"success")==0:
    for ident in response.getElementsByTagName("identifiers")[0].getElementsByTagName("identifier"):
#      print ident
      print ident.getAttribute("handle")
    sys.exit()
  else:
     print response.getElementsByTagName("message")[0].childNodes[0].nodeValue
     sys.exit(1)

def get_handle(pid):
  uri="/pids/getHandle?handle="+pid
  result=send_request(uri)
  doc=minidom.parseString(result)
  response=doc.documentElement
  if cmp(response.getAttribute("type"),"success")==0:
    identifier=response.getElementsByTagName("identifier")[0]
#    print identifier
    for property in identifier.getElementsByTagName("property"):
      print property.getAttribute("type"),property.getAttribute("value")
  else:
     print response.getElementsByTagName("message")[0].childNodes[0].nodeValue
     sys.exit(1)

def usage():
  print "Usage: ",sys.argv[0]," [options...]"
  print "Options:"
  print " -v/--verbose".ljust(30),"Verbose mode"
  print " -i/--identifier <Identifier>".ljust(30),"Specify an identifier for the current request, default is current user"
  print " -d/--domain <Domain>".ljust(30),"Specify a domain for the current request, default is df.arcs.org.au"
  print " -g/--get <Handle>".ljust(30),"Get details of a handle"
  print " -c/--create <URL>".ljust(30),"Create a handle for the given URL"
  print " -l/--list".ljust(30),"List all handles" 

def main(argv):
  try:
    opts, args = getopt.getopt(argv, "hg:lc:i:d:v", ["help", "get=", "list", "create=", "identifier=", "domain="])
  except getopt.GetoptError:
    usage()
    sys.exit(2)
  for opt, arg in opts:
    if opt in ("-h", "--help"):
      usage()
      sys.exit()
    elif opt == '-v':
      global verbose               
      verbose = True             
    elif opt in ("-i", "--identifier"):
      global identifier
      identifier = arg
    elif opt in ('-d', '--domain'):
      global domain
      domain = arg
    elif opt in ("-g", "--get"):
      get_handle(arg)
      sys.exit()
    elif opt in ("-l", "--list"):
      list_handles()
      sys.exit()
    elif opt in ("-c", "--create"):
      create_handle(arg)
      sys.exit()
  usage()


if __name__ == "__main__":
    main(sys.argv[1:])


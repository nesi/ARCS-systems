#!/usr/bin/python
import sys, os, re
from irods import *
import httplib
import getopt,getpass
import urllib
from xml.dom import minidom

request_body='<request name="mint"><properties><property name="appId" value="715a3f79b5c9e8a02a6dee9231af67c2868e80f8"/><property name="identifier" value="shunde"/><property name="authDomain" value="arcsdev.df.arcs.org.au"/></properties></request>'
domain="aaf.edu.au"
app_id="715a3f79b5c9e8a02a6dee9231af67c2868e80f8"
service_url="test.ands.org.au:8443"
verbose = False
debug = True
df_server_prefix="https://ngdata-dev.hpcu.uq.edu.au"
handle_server_prefix="http://hdl.handle.net/"
cron_update_file="/tmp/cron_pid_update"

def create_pid(file_list, result, rei):   
  user = getUser(rei.getRsComm(), rei.getRsComm().getClientUser().getUserName())    

#  if user:
#    userTuple = (user.getId(),
#                 user.getTypeName(),
#                 user.getZone(),
#                 user.getDN(),
#                 user.getInfo(),
#                 user.getComment(),
#                 str([g.getName() for g in user.getGroups() ]))
#  else:
#    userTuple = None

  global debug, df_server_prefix, handle_server_prefix

  file_list_s=file_list.parseForStr()
  username=rei.getRsComm().getClientUser().getUserName()

#  if debug==True:
#    os.system('date >> /tmp/pidtest')
#    os.system('echo "'+username+'">>/tmp/pidtest')
#    os.system('echo "'+file_list_s+'">>/tmp/pidtest')

#  info_str=re.split("ST",user.getInfo())
  info_str=user.getInfo().split("ST")
  if len(info_str)>1:
    shared_token=info_str[1][1:len(info_str[1])-2]
  else:
    shared_token=rei.getRsComm().getClientUser().getUserName()

  if debug==True:
    os.system('echo "'+shared_token+'">>/tmp/pidtest')
  filelist=file_list_s.split(",")
  result_str=[]
  for f in filelist:
    f_obj=iRodsOpen(rei.getRsComm(), f)
    if f_obj==None:
      f_obj = irodsCollection(rei.getRsComm(), f)
    if f_obj==None:
      result_str.append(f+" does not exist; ")
    else:
      if debug==True:
        rodsLog(5,str(f_obj))
        os.system('echo "creating PID for '+f+'">>/tmp/pidtest')
      global identifier
      identifier = shared_token
      try:
        pid=create_handle(df_server_prefix+f,identifier)
        if debug==True:
          os.system('echo "'+pid+'">>/tmp/pidtest')
        f_obj.addUserMetadata("PID", pid)
        f_obj.addUserMetadata("HANDLE_URL", handle_server_prefix+pid)
        result_str.append("Created PID "+pid+" for "+f+"; ")
      except Exception, err:
        if debug==True:
          os.system('echo "'+str(err)+'">>/tmp/pidtest')
        result_str.append("Failed to create PID for "+f+"; ")

  fillStrInMsParam(result, "".join(result_str))

def move_file(old_path,new_path,rei):
  user = getUser(rei.getRsComm(), rei.getRsComm().getClientUser().getUserName())
  global debug, df_server_prefix, handle_server_prefix
  old_path_s = old_path.parseForStr()
  new_path_s = new_path.parseForStr()
  f_obj = iRodsOpen(rei.getRsComm(), old_path_s)
  if debug==True:
    rodsLog(1,new_path_s)
    os.system('date >> /tmp/pidtest')
    os.system('echo moved data from "'+old_path_s+'" to "'+new_path_s+'">>/tmp/pidtest')
    os.system('echo kkkkkkkkkkkkkkkkkchecking "'+str(f_obj)+'">>/tmp/pidtest')
  if f_obj:
    f_obj.close()
    meta_data=getFileUserMetadata(rei.getRsComm(), old_path_s)
  else:
    f_obj = irodsCollection(rei.getRsComm(), old_path_s)
    if f_obj:
      meta_data=getCollUserMetadata(rei.getRsComm(), old_path_s)
    else:
      return -834000
  if debug==True:
    os.system('echo "'+str(meta_data)+'">>/tmp/pidtest')

  for m in meta_data:
    if m[0]=="PID":
      user = getUser(rei.getRsComm(), rei.getRsComm().getClientUser().getUserName())
      username=rei.getRsComm().getClientUser().getUserName()
      info_str=user.getInfo().split("ST")
      if len(info_str)>1:
        shared_token=info_str[1][1:len(info_str[1])-2]
      else:
        shared_token=rei.getRsComm().getClientUser().getUserName()
      pid=m[1]
      if debug==True:
        os.system('echo "'+shared_token+'">>/tmp/pidtest')
        os.system('echo "'+pid+'">>/tmp/pidtest')
      update_pid(pid,new_path_s,shared_token)


def update_pid(pid_s, new_path,shared_token):
  global debug, df_server_prefix, handle_server_prefix
  index=get_url_index(pid_s,shared_token)
  if debug==True:
    os.system('echo "index:'+index+'">>/tmp/pidtest')
  if len(index)>0:
    uri="/pids/modifyValueByIndex?handle="+pid_s+"&index="+index+"&value="+urllib.quote_plus(df_server_prefix+new_path)
    if debug==True:
      os.system('echo "'+uri+'">>/tmp/pidtest')
    result=send_request(uri,shared_token)
    doc=minidom.parseString(result)
    response=doc.documentElement
#  print response.getAttribute("type")
#  print cmp(response.getAttribute("type"),"success")
    if cmp(response.getAttribute("type"),"success")==0:
      identifier=response.getElementsByTagName("identifier")[0]
#      print ident
#      return identifier.getAttribute("handle")
    else:
      global cron_update_file
      os.system('echo "'+pid_s+' '+new_path+'">>'+cron_update_file)

def get_url_index(pid,shared_token):
  global result
  uri="/pids/getHandle?handle="+pid
  result=send_request(uri,shared_token)
  if debug==True:
    os.system('echo "result:'+result+'">>/tmp/pidtest')
  doc=minidom.parseString(result)
  response=doc.documentElement
  if cmp(response.getAttribute("type"),"success")==0:
    identifier=response.getElementsByTagName("identifier")[0]
#    print identifier
    for property in identifier.getElementsByTagName("property"):
      if cmp(property.getAttribute("type"),"URL")==0:
        return property.getAttribute("index")
  return ""

def construct_request_body(identifier):
  global domain,app_id
  request_body='<request name="mint"><properties><property name="appId" value="'+app_id+'"/>'
  request_body+='<property name="identifier" value="'+identifier+'"/>'
  request_body+='<property name="authDomain" value="'+domain+'"/></properties></request>'
  return request_body

def send_request(uri,identifier):
  try:
    conn = httplib.HTTPSConnection(service_url)
    if verbose == True:
      conn.set_debuglevel(9)
#      print request_body
    conn.request("POST", uri, construct_request_body(identifier))
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


def create_handle(url,identifier):
  uri="/pids/mint?type=URL&value="+urllib.quote_plus(url)
  result=send_request(uri,identifier)
  doc=minidom.parseString(result)
  response=doc.documentElement
#  print response.getAttribute("type")
#  print cmp(response.getAttribute("type"),"success")
  if cmp(response.getAttribute("type"),"success")==0:
    identifier=response.getElementsByTagName("identifier")[0]
#      print ident
    return identifier.getAttribute("handle")
  else:
    raise RuntimeError(response.getElementsByTagName("message")[0].childNodes[0].nodeValue)

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
  result=send_request(uri,"someone")
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
  identifier=getpass.getuser()
  for opt, arg in opts:
    if opt in ("-h", "--help"):
      usage()
      sys.exit()
    elif opt == '-v':
      global verbose               
      verbose = True             
    elif opt in ("-i", "--identifier"):
      identifier = arg
    elif opt in ('-d', '--domain'):
      global domain
      domain = arg
    elif opt in ("-g", "--get"):
      get_handle(arg)
      sys.exit()
    elif opt in ("-l", "--list"):
      list_handles(identifier)
      sys.exit()
    elif opt in ("-c", "--create"):
      try:
        print create_handle(arg,identifier)
        sys.exit()
      except Exception, err:
        print str(err)
        sys.exit(1)
  usage()


if __name__ == "__main__":
    main(sys.argv[1:])



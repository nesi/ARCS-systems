#!/usr/bin/python
import sys, os
from irods import *

debug=True

def check_pid(source_path, dest_path, rei):
  src_p = source_path.parseForStr()
  dest_p = dest_path.parseForStr()
  rodsLog(5,src_p)
  rodsLog(5,dest_p)
  os.system('date >> /tmp/pidtest')
  os.system('echo moving from "'+src_p+'">>/tmp/pidtest')
  os.system('echo moving to "'+dest_p+'">>/tmp/pidtest')

#  return -1
#  fillIntInMsParam(param2, num*2)

def check_pid_delete(obj_path, rei):
  global debug
  obj_p = obj_path.parseForStr()
  f_obj = iRodsOpen(rei.getRsComm(), obj_p)
  if debug==True:
    rodsLog(5,obj_p)
    os.system('date >> /tmp/pidtest')
    os.system('echo deleting "'+obj_p+'">>/tmp/pidtest')
    os.system('echo kkkkkkkkkkkkkkkkkdeleting "'+str(f_obj)+'">>/tmp/pidtest')
  if f_obj:
    f_obj.close()
    meta_data=getFileUserMetadata(rei.getRsComm(), obj_p)
  else:
    f_obj = irodsCollection(rei.getRsComm(), obj_p)
    if f_obj:
      meta_data=getCollUserMetadata(rei.getRsComm(), obj_p)
    else:
      return -834000
  if debug==True:
    os.system('echo "'+str(meta_data)+'">>/tmp/pidtest')

  for m in meta_data:
    if m[0]=="PID":
      meta_data = None
      return -41000

def check_pid_trash(obj_path, rei):
  obj_p = obj_path.parseForStr()
  rodsLog(5,obj_p)
  os.system('date >> /tmp/pidtest')
  os.system('echo trashing "'+obj_p+'">>/tmp/pidtest')
  return -1


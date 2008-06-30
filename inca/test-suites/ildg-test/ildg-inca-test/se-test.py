#!/usr/bin/env python

from xml.dom import minidom
import os
import sys
import commands
import time

srm_cmd="/opt/d-cache/srm/bin/srmcp -debug -protocols=gsiftp -streams_num=1 "
gftp_cmd="globus-url-copy -dbg "
tmp_file="file:////tmp/_copy_test_tmp_file_ildg"
xml_file=os.path.dirname(os.path.abspath(sys.argv[0]))+"/file-transfer-test.xml"
#print os.path.dirname(os.path.abspath(sys.argv[0]))

def transfer_test(fileurl,md5chksum):
#    os.system("rm -rf /tmp/_copy_test_tmp_file")
#    t1=time.time()
    if fileurl.startswith("gsiftp"):
	command=gftp_cmd+fileurl+" "+tmp_file
	print command
#	output=commands.getoutput(command)
#	sys.stderr.write("Executing: "+command+"\n")
#	sys.stderr.write(output)
#	print output
    if fileurl.startswith("srm"):
	command=srm_cmd+fileurl+" "+tmp_file
	print command
#	output=commands.getoutput(command)
#	sys.stderr.write("Executing: "+command+"\n")
#	sys.stderr.write(output)
#	print output
#    t2=time.time()
#    t_diff=t2-t1

#    chksum_cmd="echo \""+md5chksum+"  /tmp/_copy_test_tmp_file\" | md5sum --check - --status"
#    print chksum_cmd
#    chksum_result=os.system(chksum_cmd)
#    print "status:"+`os.system(chksum_cmd)`
#    if chksum_result == 0:
#	file_size=commands.getoutput("stat --format=%s /tmp/_copy_test_tmp_file")
#	transfer_speed=float(file_size)/t_diff/1024
#	print "ok "+`transfer_speed`+"kb/s"
#	print transfer_speed
#    else:
#	print "failed"
#	print output
#	transfer_speed=-1
#    os.system("rm -rf /tmp/_copy_test_tmp_file")
    return 1
#transfer_speed


def unit_test(test_grid,test_se,protocol):
    doc = minidom.parse(xml_file)
    for filetest in doc.documentElement.getElementsByTagName("file"):
#       print filetest.getElementsByTagName("se")[0].childNodes[0].nodeValue
        grid_name=filetest.getElementsByTagName("grid")[0].childNodes[0].nodeValue
        se_name=filetest.getElementsByTagName("se")[0].childNodes[0].nodeValue
        file_url=filetest.getElementsByTagName("url")[0].childNodes[0].nodeValue
#       print filetest.getElementsByTagName("md5").length
        if filetest.getElementsByTagName("md5").length > 0: md5_chksum=filetest.getElementsByTagName("md5")[0].childNodes[0].nodeValue
        if grid_name == test_grid and filetest.getElementsByTagName("accessDeny").length == 0 and file_url.startswith(protocol) and se_name == test_se:
            result=transfer_test(file_url,md5_chksum)
            if result == -1:
		return -1
	    else:
		return 0


def main():
#    print len(sys.argv)
    if len(sys.argv) < 4:
	print "Syntax: "+sys.argv[0]+" <Grid name> <SE name> <Protocol>"
	return 2
    return unit_test(sys.argv[1],sys.argv[2],sys.argv[3])




if __name__ == "__main__": sys.exit(main())

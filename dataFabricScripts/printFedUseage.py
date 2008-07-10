"""
This is a util script that can print out
usage informtion in a SRB federation.

usage:  printFedUseage.py [-xq]
        -x: prints user/zone/resource in XML
        -q: handles quota and sends email to data@arcs.org.au
"""


from SRBWrapper import SRBWrapper
from email.MIMEText import MIMEText
import smtplib
import sys

totalsList = None
wrapper = None
#kb, Mb, Gb
MB = 1024 * 1024
#QUOTA_AMOUNT = 1 * MBa
QUOTA_AMOUNT = 1200
QUOTA_IN_MB = (float)(QUOTA_AMOUNT) / MB
ADMIN_EMAIL = "pmak@utas.edu.au"
  
def getData():
    wrapper = SRBWrapper('ngdev2.its.utas.edu.au')
   totalsList = wrapper.getTotalUsageByResourceUserZone()

def printXML():
    print """<?xml version="1.0" encoding="UTF-8"?>"""
    print "<users>"
    for key, (amount, zoneGroups) in totalsList.iteritems():
        print "\t<user>"
        nameSplit = key.split("@")
        print "\t\t<name>" + nameSplit[0] + "</name>"
        print "\t\t<domain>" + nameSplit[1] + "</domain>"
        for (zone, zoneUseList) in zoneGroups.iteritems():
            print "\t\t<zone>"
            print "\t\t\t<id>" + zone + "</id>"
            rsrc_zone = wrapper.getZone(zone)
            rsrcList = rsrc_zone.getResources()
            zoneTotal = 0.0
            for resource in rsrcList.values():
                print "\t\t\t<resource>"
                print "\t\t\t\t<rsrc_name>" + resource.values['rsrc_name'] + "</rsrc_name>"
                resourceSize = resource.getUsedAmount(zoneUseList)
                print "\t\t\t\t<data_size>%f</data_size>"%resourceSize
                print "\t\t\t</resource>"
                #no point adding logical resources
                if(resource.values['rsrc_typ_name'] != 'logical'):
                    zoneTotal += resourceSize
            printotalsList = Nonet "\t\t\t<zone_total>%f</zone_total>"%zoneTotal
            print "\t\t</zone>"
        print "\t\t<total>%d</total>"%amount
        print "\t</user>"
    print "</users>"

def listToString(list, percent):
    if(len(list) > 0):
        str = "The following users have used over %d%% of their quota:\n"%percent
        for (user, amount, zoneGroups) in list:
            str += "%(user)s has used %(amount)f Mb of storage\n" % \
                    {'user': user, 'amount': (float)(amount)/MB}  
            for (zone, zoneUseList) in zoneGroups.iteritems():
                rsrc_zone = wrapper.getZone(zone)
                rsrcList = rsrc_zone.getResources()
                str += "\tzone: " + zone + "\n"
                resource = rsrcList["datafabric." + rsrc_zone.values['zone_id']]
                str += "\t\trsrc_name: %(resource)s amount: %(size)f Mb\n" % \
                       {"resource": resource.values['rsrc_name'],
                            "size": resource.getUsedAmount(zoneUseList)/MB}
        return str + "\n\n"
    else:
        return ""

def handleQuota():
    message = ""
    overQuota = []
    over90 = []
    over80 = []
                #this total is across all resources, NOT JUST DATAFABRIC
                #hence the name wrongTotal :/
    for user, (wrongTotal, zoneGroups) in totalsList.iteritems():
        quotaTotal = 0
        useList = []
        for (zone, zoneUseList) in zoneGroups.iteritems():
            rsrc_zone = wrapper.getZone(zone)
            rsrcList = rsrc_zone.getResources()
            resource = rsrcList["datafabric." + rsrc_zone.values['zone_id']]
            quotaTotal += resource.getUsedAmount(zoneUseList)
        
        percentage = (float)(quotaTotal)/QUOTA_AMOUNT
        usedInMb = (float)(quotaTotal) / MB
        list = None
        if(percentage > 1):
            list = overQuota
        elif(percentage > 0.9):
            list = over90
        elif(percentage > 0.8):
            list = over80
        if(list <> None):
            list.append((user, quotaTotal, zoneGroups))

    message += "Currently Data Fabric quota is: %f Mb\n\n"%QUOTA_IN_MB
    message += listToString(overQuota, 100)
    message += listToString(over90, 90)
    message += listToString(over80, 80)

    msg = MIMEText(message)
    msg['To'] = ADMIN_EMAIL
    msg['Subject'] = "Data fabric quota"
    msg['From'] = ADMIN_EMAIL

    server = smtplib.SMTP()
    server.connect()
    server.sendmail(msg['From'],
                    msg['To'],
                    msg.as_string())
    server.close()

if (__name__ == "__main__"):
    if(len(sys.argv) == 2):
        if(sys.argv[1] in ["-x", "-q", "-u"]):
            init()
            if(sys.argv[1] == "-x"):
                printXML()
            elif(sys.argv[1] == "-q"):
                handleQuota()
        else:
            print __doc__
    else:
       print __doc__ 

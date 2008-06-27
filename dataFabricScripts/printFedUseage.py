#!/usr/bin/python

"""
This prints out an XML with for storage used by
any user in the federation.  It's grouped by the
*resource* zone (i.e. zone that user is writing to)
and then by resources within each zone.  Finally,
a total across all zones is also included

It's a bit slow - it makes n^2 queries, where n is 
the number of federated zones.
"""

from SRBWrapper import SRBWrapper
wrapper = SRBWrapper()

totalsList = wrapper.getTotalUsageByResourceUserZone()
print """<?xml version="1.0" encoding="UTF-8"?>"""

for key, (amount, zoneGroups) in totalsList.iteritems():
    print "<user>"
    nameSplit = key.split("@")
    print "\t<name>" + nameSplit[0] + "</name>"
    print "\t<domain>" + nameSplit[1] + "</domain>"
    for (zone, zoneUseList) in zoneGroups.iteritems():
        print "\t<zone>"
        print "\t\t<id>" + zone + "</id>"
        for use in zoneUseList:
            print "\t\t<resource>"
            print "\t\t\t<phy_rsrc_name>" + use.values['phy_rsrc_name'] + "</phy_rsrc_name>"
            print "\t\t\t<data_size>" + use.values['data_size'] + "</data_size>"
            print "\t\t</resource>"
        print "\t</zone>"
    print "\t<total>%d</total>"%amount
    print "</user>"


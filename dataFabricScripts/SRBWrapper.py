from SRBResult import SRBResult, SRBUser, SRBZone

#----------------------------------------------------------------
# CHANGELaOG
# 2008-06-27: added getTotalUsageByResourceUserZone
#----------------------------------------------------------------

class SRBWrapper:
    def __init__(self):
        self.knownZones = self.getKnownZones()
        #admin zone
        self.zone = self.getZone('srb.tpac.org.au')
                                # Gb - Mb - Kb  
        #self.quotaLimit = 25 * 1024 * 1024 * 1024
        #self.zone.setQuota('data_fabric', 25 * 1024 & 1024 *1024)
        #self.zone.setQuota('data_fabric', 120 * 1024 *1024)
        #self.zone.setQuota('ngdev2.its.utas.edu.au', 1000 * 1024 * 1024)
        self.zone.setQuota('srb.tpac.org.au', 25 * 1024 * 1024 * 1024)    

    def getKnownZones(self):
        lines = SRBResult.getOutputLines('/usr/bin/Stoken Zone', 
                    'Error getting known zones')
        zonesList = SRBResult.parseAsType(lines, 14, SRBZone)
        return zonesList
 
    def getZone(self, zone_id):
        for zone in self.knownZones:
            if(zone.values['zone_id'] == zone_id):
                return zone
        return None

    def getAllKnownUsers(self):
        usersList = []
        for zone in self.knownZones:
            for user in zone.getUsers():
                usersList.append(user)
        return usersList


    def printLocalUserTotal(self):
        """Prints out usage of users in YOUR LOCAL ADMIN ZONE
            for all resources they have used across the
            federation"""
        myUsers = self.zone.getUsers()
        for user in self.getAllKnownUsers():
            print "----------------------------------------------------"
            print "user_name: " + user.values['user_name'] + "@" + user.values['domain_desc']
            resource_zone = [z for z in self.knownZones if (z.values['zone_status'] == '1')]
            userTotal = 0
            for rzone in resource_zone:
                uses = user.getUsageByResource(rzone.values['zone_id'])
                if(len(uses.keys()) > 0):
                    print "zone: " + rzone.values['zone_id']
                    for rs_name, use in uses.iteritems():
                        print "\tphy_rsrc_name: " + rs_name
                        print "\tdata_size: " + use.values['data_size']
                        userTotal += (long)(use.values['data_size'])
            print "Total amount of data across federation: " + `((float)(userTotal)/1024/1024)` + " Mb"
        print "----------------------------------------------------"

    def printLocalResourceUsage(self):
        table = self.zone.getTotalByResource()
        for rs, amount in table.iteritems():
            print "----------------------------------------------------"
            print "rsrc_name: " + rs
            print "used: " + `amount`

    def getTotalUsage(self):
        totalsList = {}
        #Only list zones that are "active"
        zones =  [z for z in self.knownZones if (z.values['zone_status'] == '1')] 
        for zone in zones:
            for zone2 in zones:
                userDomain = zone2.values['domain_desc']
                usages = zone.getUsageForUserDomain(userDomain)
                for use in usages:
                    key = (use.values['user_name'], userDomain)
                    size = (int)(use.values['data_size'])
                    count = (int)(use.values['data_id'])
                    if(totalsList.has_key(key)):
                        (oldSize, oldCount) = totalsList[key]
                        totalsList[key] = ((oldSize + size), (oldCount + count))
                    else:
                        totalsList[key] = (size, count)
        return totalsList


    def getTotalUsageByResourceUserZone(self):
        """This grabs usage info on users who have
            written something to the data fabric.
            No Sput, no record.
            It returns a dictionary with:
                key -> usr@userDomain
                value -> (total, {zone -> [resource in zone])
        """
        totalsList = {}
        #Only list zones that are "active"
        zones =  [z for z in self.knownZones if (z.values['zone_status'] == '1')]
        for zone in zones:
            resourceZoneId = zone.values['zone_id']
            for zone2 in zones:
                userDomain = zone2.values['domain_desc']
                #yes, we want to group by resource
                usages = zone.getUsageForUserDomain(userDomain, True)
                if(len(usages)> 0):
                    for use in usages:
                        size = (long)(use.values['data_size'])
                        key = use.values['user_name'] + "@" + userDomain
                        if(totalsList.has_key(key)):
                            (amount, zoneGroups) = totalsList[key]
                            amount = amount + size
                            if(zoneGroups.has_key(resourceZoneId)):
                                zoneGroups[resourceZoneId].append(use)
                            else:
                                zoneGroups[resourceZoneId] = [use]
                            totalsList[key] = (amount, zoneGroups)    
                        else:
                            totalsList[key] = (size, {resourceZoneId : [use]})
	return totalsList
                    

from SRBResult import SRBResult, SRBUser, SRBZone

class SRBWrapper:
    def __init__(self):
        self.knownZones = self.getKnownZones()
        #admin zone
        self.zone = self.getZone('ngdev2.its.utas.edu.au')
                                # Gb - Mb - Kb  
        #self.quotaLimit = 25 * 1024 * 1024 * 1024
        #self.zone.setQuota('data_fabric', 25 * 1024 & 1024 *1024)
        self.zone.setQuota('data_fabric', 1 * 1024 *1024)
        self.zone.setQuota('ngdev2.its.utas.edu.au', 1000 * 1024 * 1024)

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

    def getTotalUsage(self):
        totalsList = {}
        #Only list zones that are "active"
        zones =  [z for z in self.knownZones if (z.values['zone_status'] == '1')] 
        for zone in zones:
            for zone2 in zones:
                userDomain = zone2.values['domain_desc']
                usages = zone.getUsageInZone(userDomain)
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

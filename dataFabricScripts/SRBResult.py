import re
import os

#A lot of funcationality here is "borrowed/stolen" from 
#the Taiwan scipt for usage statstics.  
#The original is here: http://srb.grid.sinica.edu.tw/asmss/



#----------------------------------------------------------------
# CHANGELOT
# 2008-06-18: 
#   - added SRBResource class for handling quotas
#   - quota should be identified by rsrc_name, not phy_rsrc_name
#
#----------------------------------------------------------------

#---static goodness
class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable

#---------------------------------------------------------------------------------------------

#This is thrown whenver output from an Scommand
#cannot be read
class SRBException(Exception):
    def __init__(self, value):
        self.value = value
    
    def __str__(self):
        return repr(self.value)
#---------------------------------------------------------------------------------------------

class SRBResult(object):
    """This class is used for storing results from
        a SRBCommand - essentially lumps results
        into {key => value} pairs which are accessible
        through the .value dictionary"""

    pattern = re.compile("(.*): (.*)\s")

    def __init__(self, result = None):
        """Creates a SRBResult object
            where result is a list of 
            line ouptut from SRB commands """
        if(result <> None):
            self.values = {}
            for line in result:
                split = re.match(SRBResult.pattern, line)
                if(len(split.groups()) == 2):
                    self.values[split.group(1)] = split.group(2)

    def getOutputLines(cmd, error):
        """Grabbing stuff from Scommand, stolen from ZoneUserSync """
        lines = []
        try:
            lines = os.popen(cmd).readlines()
            #exclude lines beginning with '-'
            lines = [x for x in lines if (x[0] <> '-')]
            return lines
        except:
            raise SRBException(error)

    def toString(self):
        """Convinience function for printing out
            key/value pairs this SRBResult stores"""
        str = ""
        for key, value in self.values.iteritems():
            str += key + ": " + value + "\n"
        return str[:-1]

    def parse(lines, numElements):
        """Constructs a list of SRBResult
            based on (expected) lines of ouptut from SRB commands.
            numElements is the count for the number of
            elements between each SRB records (note that
            the separator lines are removed at this point"""
        srbResults = []
        if(len(lines) > 0):
            for j in range(0, (len(lines)/numElements)):
                sIndex = j * numElements
                srbResults.append(SRBResult(lines[sIndex:(sIndex + numElements)]))
        return srbResults

    def parseAsType(lines, numElements, Type):
        """Returns a list of Types.  They should be SRBResult
            or subclasses of it.  I can't explain why it works
        """
        srbResults = []
        if(len(lines) > 0):
            for j in range(0, (len(lines)/numElements)):
                sIndex = j * numElements
                srbResults.append(Type(lines[sIndex:(sIndex + numElements)]))
        return srbResults

    #-----------------------------------------------
    # "static" methods :)
    parse = Callable(parse) 
    parseAsType = Callable(parseAsType)
    getOutputLines = Callable(getOutputLines)

#---------------------------------------------------------------------------------------------

class SRBUser(SRBResult):
    """No surprise here - this class represents
        a SRB user"""
    def __init__(self, result):
        super(SRBUser, self).__init__(result)

    def setZone(self, _zone):
        self.zone = _zone

    def getUsageInZone(self, zone_id):
        lines = SRBResult.getOutputLines('/usr/bin/SgetColl -e /' +
                self.getHomeCollection(zone_id) +  "*",
                'Error getting user space usage statistics')
        if(len(lines) == 3):
            stats = SRBResult(lines)
            return stats
        return None

    def isOverLocalQuota(self, limit):
        return self.isOverQuota(limit, self.values['zone_id'])

    def isOverQuota(self, limit, zone_id):
        """Returns true if the TOTAL usage within the specified zone
            i.e. across all resources are over the limit value.  Note
            that the limit and the total are in BYTES"""
        stats = self.getUsageInZone(zone_id)
        if(stats <> None):
            size = (int)(stats.values['data_size'])
            if(size > limit):
                return True
            else:
                return False
        return False

    def getUsageByResource(self, zone_id):
        """zone_id = name of resource zone(?)"""
        lines = SRBResult.getOutputLines('/usr/bin/SgetColl -f /' +
                self.getHomeCollection(zone_id) +  "*",
                'Error getting user space usage statistics')
        usages = SRBResult.parse(lines, 3)
        table = {}
        for use in usages:
            table[use.values['phy_rsrc_name']] = use
        return table

    def getLocalHomeCollection(self):
        return self.getHomeCollection(self.values['zone_id'])

    def getHomeCollection(self, zone_id):
        return zone_id + "/home/" + self.values['user_name'] + "." + self.values['domain_desc']

#---------------------------------------------------------------------------------------------

class SRBZone(SRBResult):
    """This class represents a SRB zone..."""
                    #Mb, Kb
    DISPLAY_SIZE = 1024 * 1024    

    def __init__(self, result):
        super(SRBZone, self).__init__(result)
        self.resourceList = {}
        if(self.values['zone_status'] == '1'):
            self.getResources() 

    def getResources(self):
        self.resourceList = {}
        netprefix = self.values['netprefix']
        host = netprefix[:netprefix.find(":")]
        lines = SRBResult.getOutputLines('/usr/bin/SgetR -z ' + self.values['zone_id'],
                    'Errpr getting resources for zone')
                                       #first line of output says QueryZone = blah
        list = SRBResult.parseAsType(lines[1:], 12, SRBResourceFactory)
        for rs in list:
            if(self.resourceList.has_key(rs.values['rsrc_name'])):
                self.resourceList[rs.values['rsrc_name']].addResource(rs)
            else:
                self.resourceList[rs.values['rsrc_name']] = rs
        return self.resourceList

    def getUsersInDomain(domain):
        usersList = []
        lines = SRBResult.getOutputLines('/usr/bin/SgetU -P -M ' + domain,
                    'Error getting user info')
        usersList = SRBResult.parseAsType(lines, 7, SRBUser)
        return usersList

    def getUsers(self):
        """Grabs a list of SRBUser, as with the usual SgetU 
            command for a specified group (_group)"""
        usersList = SRBZone.getUsersInDomain(self.values['domain_desc'])
        return usersList

    def setQuota(self, resource, limit):
        if(self.resourceList.has_key(resource)):
            self.resourceList[resource].setQuota(limit)

    def getUsageInfo(self, userDomain):
        """Grabs all usage of a specific zone for 
            user of the specified userDomain"""
        lines = SRBResult.getOutputLines('/usr/bin/SgetColl -e ' +
                self.values['zone_id'] + "/home/*" + "." + userDomain + "*",
                'Error getting user space usage statistics')
        results = SRBResult.parse(lines, 3)
        return results

    def getUsageInZone(self, userDomain):
        """Grabs all usage of a specific storage zone for 
            user of the specified userDomain"""
        lines = SRBResult.getOutputLines('/usr/bin/SgetColl -e ' +
                self.values['zone_id'] + "/home/*" + "." + userDomain + "*",
                'Error getting user space usage statistics')
        results = SRBResult.parse(lines, 3)
        return results

    def printLocalResourceReport(self):
        users = self.getUsers()
        for user in users:
            resources = user.getUsageByResource(self.values['zone_id'])
            if(len(resources) > 0):            
                print "---------------------------------------------------"
                print "user_name: " + user.values['user_name']
                for rsc, use in resources.iteritems():
                    print use.toString()

    def sendNastygram(self, percentage, user, useageInfo):
        #should do something meaningful here
        
        print "TODO: send email to user " + user.values['user_name'] + user.values['user_email']

    def handleQuota(self, user):
        usages = user.getUsageByResource(self.values['zone_id'])
        for rsc, use in usages.iteritems():
            usedAmount = (float)(use.values['data_size'])
            quotaPercentage = (usedAmount / self.quotas[use.values['rsrc_name']])
            if(quotaPercentage > 0.8):
                self.sendNastygram(quotaPercentage, user, use)
    def printUsageReport(self, user, displaySize = None):
        if(displaySize == None):
            displaySize = SRBZone.DISPLAY_SIZE
        usages = user.getUsageByResource(self.values['zone_id'])
        for rs in self.resourceList:
            if(self.resourceList[rs].hasQuota):
                self.resourceList[rs].printQuota(user, usages, displaySize)

    #--static goodness
    getUsersInDomain = Callable(getUsersInDomain)

#---------------------------------------------------------------------------------------------

class SRBResource(SRBResult):
    def __init__(self, list = None):
        super(SRBResource, self).__init__(list)
        self.hasQuota = False

    #limit is in BYTES
    def setQuota(self, _limit):
        self.limit = _limit
        self.hasQuota = True

    def printQuota(self, user, usages, displaySize):
        rsName = self.values['rsrc_name']
        print "------------------------------------------------------"
        print "user_name: " + user.values['user_name'] + "@" + user.values['domain_desc']
        print "quota: %3.3f Mb"%(self.limit / displaySize)
        print "phy_rsrc_name: " + rsName
        #if the user hasn't put anything on the resource, then
        #there will be no record in usages.  So it will be al;
        #quota amount will be available
        usedAmount = 0.00
        quotaPercentage = 1.00       
        data_id = 0

        (usedAmount, data_id) = self.getAmountAndCount(usages)

        print "data_size: %3.3f Mb"%(usedAmount / displaySize)
        print "data_id: " + `data_id`
        print "free: %3.3f Mb"%((self.limit - usedAmount) / displaySize)
        print "percentage: %3.3f%%"%(quotaPercentage * 100)

    def handleQuota(self, user, usage):
        return True    

    def getAmountAndCount(self, usages):
        return (self.getUsedAmount(usages),
                    self.getNumFiles(usages))

    def getNumFiles(self, usages):
        return (int)(usages[rsName].values['data_id'])

    def getUsedAmount(self, useages):
        return (float)(usages[rsName].values['data_size'])

    def isOverSoftQuota(self, user):
        return False

    def isOverHardQuota(self, user):
        return False

#----------------------------------------------------------------------------------------------
class SRBLogicalResource(SRBResource):
    #contains a list of SRBResource
    def __init__(self, list = None):
        super(SRBLogicalResource, self).__init__(list)
        self.resourceList = {}
        #I know... this is kind of redundant
        rs = SRBResource(list)
        self.resourceList[rs.values['phy_rsrc_name']] = rs

    def addResource(self, rs):
        self.resourceList[rs.values['phy_rsrc_name']] = rs

    def getUsedAmount(self, usages):
        total = 0.0
        for rsName in self.resourceList.keys():
            if(usages.has_key(rsName)):
                total += (float)(usages[rsName].values['data_size'])
        return total
 
    def getNumFiles(self, usages):
        
        total = 0
        for rsName in self.resourceList.keys():
            if(usages.has_key(rsName)):
                total += (int)(usages[rsName].values['data_id'])
        return total

#----------------------------------------------------------------------------------------------
def SRBResourceFactory(result):
    """A fun factory of SRB resource... 
        Logical is the only 'special' case"""
    #hmm... a bit dogey
    if(result[2].find('logical') > -1):
        lr = SRBLogicalResource(result)
        return lr
    else:
        rs = SRBResource(result)
        return rs


    

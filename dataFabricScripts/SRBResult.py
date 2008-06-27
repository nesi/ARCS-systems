import re
import os
import smtplib
from email.MIMEText import MIMEText

#A lot of funcationality here is "borrowed/stolen" from 
#the Taiwan scipt for usage statstics.  
#The original is here: http://srb.grid.sinica.edu.tw/asmss/



#----------------------------------------------------------------
# CHANGELOG
# 2008-06-18: 
#   - added SRBResource class for handling quotas
#   - quota should be identified by rsrc_name, not phy_rsrc_name
# 2008-06-23:
#   - woops.  Resource should be identified by phy_rsrc_name, since
#       usages are SRB only returns phy_rsrc_names with SgetColl
#   - implemented email sending when over 80% of quota
#   - implmeneted SRBZone.getTotalByResource - total number of 
#        bytes used per resource
# 2008-06-27:
#   - SRBZone now delays getting resources list until required
#   - changed SRBZone.getUsageForUserDomain - this has an option   
#     torgroup result by resource.
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
                newObj = Type(lines[sIndex:(sIndex + numElements)])
                srbResults.append(newObj)
                
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

    def setLocalZone(self, _zone):
        self.zone = _zone

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

    def getResources(self):
        if(len(self.resourceList) > 0):
            return self.resourceList

        #netprefix = self.values['netprefix']
        #host = netprefix[:netprefix.find(":")]
        lines = SRBResult.getOutputLines('/usr/bin/SgetR -z ' + self.values['zone_id'],
                    'Errpr getting resources for zone')
         
        #first line of output says QueryZone = blah
        list = SRBResult.parseAsType(lines[1:], 12, lambda x: SRBResourceFactory(self, x)) 
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
        for user in usersList:
            user.setLocalZone(self)
        return usersList

    def setQuota(self, resource, limit):
        self.getResources()
        if(self.resourceList.has_key(resource)):
            self.resourceList[resource].setQuota(limit)

    def getUsageForUserDomain(self, userDomain, groupByResource = False):
        """Grabs all usage of a specific storage zone for 
            user of the specified userDomain"""

        numRows = 3
        cmd = '/usr/bin/SgetColl -e '

        if(groupByResource):
            cmd += " -f "
            numRows = 4
        cmd += "/" + self.values['zone_id'] + "/home/*" + "." + userDomain + "*"

        lines = SRBResult.getOutputLines(cmd, 'Error getting user space usage statistics')
        results = SRBResult.parse(lines, numRows)
        return results

    def getTotalByResource(self):
        """Returns a dictionary of resource name (both logical
            and physical and other seemingly randome ones) with 
            the amount of used space in bytes"""
        self.getResources()
        lines = SRBResult.getOutputLines('/usr/bin/SgetColl -f /' +
               self.values['zone_id'] + "/home/*",
                'Error getting total stored by resources')
        uses = SRBResult.parse(lines, 3)
        #return results
        table = {}
        for rs in uses:
            table[rs.values['phy_rsrc_name']] = rs

        result = {}
        for rsName, rs in self.resourceList.iteritems():
            result[rsName] = rs.getUsedAmount(table)
        return result

    def handleQuota(self, user):
        self.getResources()
        usages = user.getUsageByResource(self.values['zone_id'])
        for rsName, rs in self.resourceList.iteritems():
            if(rs.hasQuota):
                rs.handleQuota(user, usages)
                                
    def printUsageReport(self, user, displaySize = None):
        """Prints the usage report for a user zone"""
        if(displaySize == None):
            displaySize = SRBZone.DISPLAY_SIZE
        self.getResources()
        usages = user.getUsageByResource(self.values['zone_id'])
        for rsName, rs in self.resourceList.iteritems():
            if(rs.hasQuota):
                rs.printQuota(user, usages, displaySize)

    #--static goodness
    getUsersInDomain = Callable(getUsersInDomain)

#---------------------------------------------------------------------------------------------

class SRBResource(SRBResult):
    def __init__(self, zone, list = None):
        super(SRBResource, self).__init__(list)
        self.hasQuota = False
        self.zone = zone
    def setZone(self, _zone):
        self.zone = _zone

    #limit is in number of BYTES.  It will be converted to a FLOAT
    def setQuota(self, _limit):
        self.limit = (float)(_limit)
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

    def handleQuota(self, user, usages):
        usedAmount = self.getUsedAmount(usages)
        quotaPercentage = (usedAmount / self.limit)
        if(quotaPercentage > 0.8):
            self.sendNastygram(quotaPercentage, user, usedAmount)

    def sendNastygram(self, percentage, user, usedAmount):
        #should do something meaningful here
        if(percentage > 1):
            percent = 100
        else:
            percent = ((int)(percentage * 100)) /10
            percent = percent * 10

        quotaInMb = self.limit / 1024 / 1024
        usedInMb = usedAmount / 1024 / 1024 

        message = "Dear data fabric user,\n\n"

        message += "This is a generated message sent to notify you of your use of "
        message += "the ARCS Data Fabric service.  You have exceeded " + `percent` + "% "
        message += "of your allowed quota of " + `quotaInMb` + " Mb.  At the time this "
        message += "message was generated, you have used " + `usedInMb` + " Mb. \n\n" 

        message += "If you have any further questions, you can log a request "
        message += "for help at help@arcs.org.au"

        msg = MIMEText(message)
        #msg['To'] = user.values['user_email']
        msg['To'] = "pmak@utas.edu.au"
        #msg['Cc'] = get admin email??
        msg['Subject'] = "Warning: Account '" + user.values['user_name'] + "@" + user.values['domain_desc'] + "' is over " + `percent` + "% of quota"
        msg['From'] = 'srbAdmin@' + self.values['domain_desc']
        
        server = smtplib.SMTP()
        server.connect()
        server.sendmail(msg['From'], 
                        msg['To'], 
                        msg.as_string())
        server.close()

    def getDefaultPath(self):
        path = self.values['phy_default_path']
        return path[:path.find('?')]

    def getAmountAndCount(self, usages):
        return (self.getUsedAmount(usages),
                    self.getNumFiles(usages))

    def getNumFiles(self, usages):
        rsName = self.values['phy_rsrc_name']
        if(usages.has_key(rsName)):
            return (int)(usages[rsName].values['data_id'])
        else:
            return 0

    def getUsedAmount(self, usages):
        rsName = self.values['phy_rsrc_name']
        if(usages.has_key(rsName)):
            return (float)(usages[rsName].values['data_size'])
        else:
            return 0

#----------------------------------------------------------------------------------------------

class SRBLogicalResource(SRBResource):
    #contains a list of SRBResource
    def __init__(self, zone, list = None):
        super(SRBLogicalResource, self).__init__(zone, list)
        self.resourceList = {}
        self.zone = zone
        #I know... this is kind of redundant
        rs = SRBResource(zone, list)
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

def SRBResourceFactory(zone, result):
    """A fun factory of SRB resource... 
        Logical is the only 'special' case"""
    #hmm... a bit dogey
    if(result[2].find('logical') > -1):
        lr = SRBLogicalResource(zone, result)
        return lr
    else:
        rs = SRBResource(zone, result)
        return rs

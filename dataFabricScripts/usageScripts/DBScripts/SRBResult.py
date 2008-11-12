import re
import os
import popen2
from subprocess import Popen, PIPE
from datetime import datetime
from os import kill, waitpid, WNOHANG
from time import sleep
import signal

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
# 2008-06-30:
#   - quota is now applied to federated storage rather than 
#     individual resources.  Therefore, handleQuota has been
#     removed from SRBZone and SRBResource
# 2008-06-16:
#   - users now belongs to domain, rather than zones.  Other methods
#       have been changed acoordingly
# 2008-08-21:
#   - added timeout for Scommands - sometimes hosts cannot be
#       contacted or is really erally slow.  To change the wait 
#       time in seconds, use the value TIMEOUT_SECONDS
#----------------------------------------------------------------

#---static goodness
class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable


#give it a nice generous 30 seconds
#Scommand hangs if SRB host is down.  Or just really really slow....
TIMEOUT_SECONDS = 10

#---------------------------------------------------------------------------------------------

class SRBTimeoutException(Exception):
    def __init__(self, cmd, value):
        self.cmd = cmd
        self.value = value

    def __str__(self):
        return "Time out while running: " + self.cmd + " " + self.value
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
                    if(self.values.has_key(split.group(1))):
                        count = len([x for x in self.values.keys() if(x.find(split.group(1)) > -1)])
                        self.values[split.group(1) + `count`] = split.group(2)
                    else:
                        self.values[split.group(1)] = split.group(2)
    def insertValues(self, map):
        self.values = map
    
    def getOutputLines(cmd, error):
        """Grabbing stuff from Scommand, stolen from ZoneUserSync """
        lines = []
        try:
            FNULL = open('/dev/null', 'w')
            #timeout code borrowed from:
            #http://code.pui.ch/2007/02/19/set-timeout-for-a-shell-command-in-python/
            #This will not work under Windows...
            procStart = datetime.now()
            proc = Popen(cmd.split(), shell=False, stdin=PIPE, stdout=PIPE, stderr=FNULL, close_fds=True)

            while(proc.poll() is None):
                #poll once every 10th of a second
                sleep(0.1)
                lapsed = (datetime.now() - procStart).seconds
                if(lapsed > TIMEOUT_SECONDS):
                    os.kill(proc.pid, signal.SIGKILL)
                    os.waitpid(-1, os.WNOHANG)
                    raise SRBTimeoutException(cmd, error)
            (r, e) = (proc.stdout, proc.stderr)
            lines = r.readlines()
            r.close()
            if(e <> None):
                e.cloes()
            
            #exclude lines beginning with '-'
            lines = [x for x in lines if (x[0] <> '-')]
            return lines
        except KeyboardInterrupt:
            #Kill them... ALLL OF THEM.....
            os.killpg(os.getpid(), signal.SIGKILL)
        except Exception, e:
            #We'll just capture the exception here...
            #and returb an empty list.  
            print e
            return []
         
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
    def __init__(self, result = None):
        super(SRBUser, self).__init__(result)

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
class SRBGroup(SRBResult):
    """Groups"""
    def __init__(self, result = None):
        super(SRBGroup, self).__init__(result)


#-----------------------------------------------------------------------------------
class SRBDomain(SRBResult):
    def __init__(self, result = None):
        super(SRBDomain, self).__init__(result)
        self.users = self.getAllUsers()

    def getUser(self, userName):
        lines = SRBResult.getOutputLines("/usr/bin/SgetU -P " + userName +
                 "@" + self.values['domain_desc'], "Unable to get local user " +
                userName + "'s infomration")
        if(len(lines) == 7):
            return SRBUser(lines)
        else:
            return None

    def hasUsers(self):
        return (len(self.users) <> 0)

    def getAllUsers(self):
        usersList = []
        lines = SRBResult.getOutputLines('/usr/bin/SgetU -P -M ' + 
                    self.values['domain_desc'],
                    'Error getting user info')
        usersList = SRBResult.parseAsType(lines, 7, SRBUser)
        return usersList

    def getUsageForUserDomain(self, zone_id, groupByResource = False):
        """Grabs all usage of a specific storage zone for 
            user of the specified userDomain"""

        numRows = 3
        cmd = '/usr/bin/SgetColl -e '

        if(groupByResource):
            cmd += " -f "
            numRows = 4
        cmd += "/"  + zone_id + "/home/*" + "." + self.values['domain_desc'] + "*"

        lines = SRBResult.getOutputLines(cmd, 'Error getting user space usage statistics')
        results = SRBResult.parse(lines, numRows)
        return results

#-----------------------------------------------------------------------------------

class SRBZone(SRBResult):
    """This class represents a SRB zone..."""
                    #Mb, Kb
    DISPLAY_SIZE = 1024 * 1024    

    def __init__(self, result = None):
        super(SRBZone, self).__init__(result)
        self.resourceList = {}
        self.adminUser = None

    def getAdminUser(self):
        if(self.adminUser == None):
            self.adminUser = self.getUser(self.values['user_name'])
        return self.adminUser

    def getResource(self, name):
        return self.resourceList[name]

    def getResources(self, onlineOnly = True):
        if(len(self.resourceList) > 0):
            return self.resourceList

        cmd = '/usr/bin/SgetR '
        if(onlineOnly):
            cmd += "-l "

        cmd +=  "-z " + self.values['zone_id']
        lines = SRBResult.getOutputLines(cmd,
                    'Errpr getting resources for zone')

        #first line of output says QueryZone = blah       

        list = SRBResult.parseAsType(lines[1:], 21, lambda x: SRBResourceFactory(self, x))
        for rs in list:
            if(rs.values['rsrc_typ_name'] == 'logical'):
                if(self.resourceList.has_key(rs.values['rsrc_name'])):
                    self.resourceList[rs.values['rsrc_name']].addResource(rs)
                else:
                    self.resourceList[rs.values['rsrc_name']] = rs
            else:
                self.resourceList[rs.values['rsrc_name']] = rs
        return self.resourceList

    def setQuota(self, resource, limit):
        self.getResources()
        if(self.resourceList.has_key(resource)):
            self.resourceList[resource].setQuota(limit)

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

                               
    def printUsageReport(self, user, displaySize = None):
        """Prints the usage report for a user zone"""
        if(displaySize == None):
            displaySize = SRBZone.DISPLAY_SIZE
        self.getResources()
        usages = user.getUsageByResource(self.values['zone_id'])
        for rsName, rs in self.resourceList.iteritems():
            if(rs.hasQuota):
                rs.printQuota(user, usages, displaySize)
#---------------------------------------------------------------------------------------------

class SRBResource(SRBResult):
    def __init__(self, zone, list = None):
        super(SRBResource, self).__init__(list)
        self.hasQuota = False
        #A resource can only belong to a zone...
        self.zone = zone

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
        for use in usages:
            if(use.values['phy_rsrc_name'] == rsName):
                return (float)(use.values['data_size'])
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
        for use in usages:
            if(use.values['phy_rsrc_name'] in self.resourceList.keys()):
                total += (float)(use.values['data_size'])
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

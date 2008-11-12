import MySQLdb
import MySQLdb.cursors
import datetime
from StatsDBObjects import *
from statsXMLReader import *

LOCAL_ZONE = 'srbdev.sf.utas.edu.au'

def getAll(db, Type):
        sql = "SELECT * FROM " + Type.tableName
        records = db.executeStatement(sql)
        results = []
        if(records <> None):
            for r in records:
                results.append(Type(db, r))
        return results

#------------------------------------------------------------
class StatsDB(StatsDBConnector):
    XMLDIR = '/%s/projects/dataFabricStats/'%LOCAL_ZONE
    
    def __init___(self):
        self.zones = []
        self.domains = []
        self.resourceTypes = []
        
    def connectDB(self, _host, _user, _password, _dbName):
        super(StatsDB, self).connectDB(_host, _user, _password, _dbName)
        #must get atomic types first
        self.resourceTypes = getAll(self, DBResourceType)
        self.zones = getAll(self, DBZone)
        self.domains = getAll(self, DBDomain)
        self.groups = getAll(self, DBGroup)
        return True

        #ugly...
    def notInDB(self, srbList, dbList, valueName, fieldName):
        if(len(valueName) <> len(fieldName)):
            raise Exception("field values Not same length")
        result = []
        if(len(dbList) == 0):
            return srbList
        for srbItem in srbList:
            found = False
            for dbItem in dbList:
                #matches all fields and values
                match = True
                for i in range (0, len(valueName)):
                    match = (match and 
                            (srbItem.values[valueName[i]] == 
                                dbItem.fields[fieldName[i]]))
                if(match):
                    found = True
                    break
            if(not(found)):
                result.append(srbItem)
        return result

    def getValue(self, list, field, value):
        for item in list:
            if(item.fields[field] == value):
                return item
        return None

    def getZone(self, zoneName):
        return self.getValue(self.zones, 'name', zoneName)

    def getDomain(self, domainName):
        return self.getValue(self.domains, 'name', domainName)

    def getResourceType(self, rs_type):
        return self.getValue(self.resourceTypes, 'name', rs_type)

    def getResourceTypeById(self, id):
        return self.getValue(self.resourceTypes, 'id', id)

    def getGroup(self, groupName, zoneName):
        z = self.getZone(zoneName)
        return z.getGroup(groupName)

    def addLog(self, processZone, xml_timestamp, filename):
        #Ah, repeating my own code.  Should really make this a method...
        zone = self.getZone(processZone)
        reader = StatsXMLReader(filename)
        reader.getDBObjects() 
        print "\tinserting user usage values"
        for usr in reader.userList:
            user = (self.getDomain(usr.map['domain'])).getUser(usr.map['name'])
            for rsc in usr.resourceList:
                (resourceName, amount, count) = rsc
                dbResource = self.getZone(zone.fields['name']).getResource(resourceName, resourceName)
                DBUseLogEntry.addUser(self, user, dbResource, (long)(amount[:-2]), (long)(count), xml_timestamp)
        print "\tinserting group usage values"
        for grp in reader.groupList:
            group = self.getGroup(grp.map['name'], grp.map['zone'])
            if(group == None):
                group = DBGroup.add(self, grp.map['name'], grp.map['zone'])
            for rsc in grp.resourceList:
                (resourceName, amount, count) = rsc
                dbResource = self.getZone(zone.fields['name']).getResource(resourceName, resourceName)
                DBUseLogEntry.addGroup(self, group, dbResource, (long)(amount[:-2]), (long)(count), xml_timestamp)

    def checkHasValuesToday(self, zone, today):
        sql = """SELECT timestamp FROM use_log WHERE user_id 
                IN (SELECT users.id FROM users, zones WHERE 
                users.zone_id = zones.id and 
                zones.name = '%s') and
                DATE(timestamp) = DATE('%s')
                LIMIT 1"""%(zone,today) 

        row = self.executeStatement(sql)
        if(row == None):
            return False
        else:
            return True

    def checkHasValuesXMLTimestamp(self, zone, timestamp):
        sql = """SELECT timestamp FROM use_log WHERE user_id 
                IN (SELECT users.id FROM users, zones WHERE 
                users.zone_id = zones.id and 
                zones.name = '%s') and
                xml_timestamp = '%s'
                LIMIT 1"""%(zone, timestamp)

        row = self.executeStatement(sql)
        if(row == None):
            return False
        else:
            return True



    def initDB(self, wrapper):
        """Grabs values out of (or add to) DB for everything 
            except for log entires"""
        print "Initialising database..."
        srbResourceTypes = wrapper.getResourceTypes()
        srbZones = wrapper.getKnownZones()
        srbDomains = wrapper.getKnownDomains()
        
        #---------------------------------------------------------------
        diff = self.notInDB(srbResourceTypes, self.resourceTypes, 
                                ['rsrc_typ_name'], ['name'])
        for rs in diff:
            print "adding resource: " + rs.values['rsrc_typ_name']
            rsResourceType = DBResourceType.add(self, rs)
            self.resourceTypes.append(rsResourceType)
        #---------------------------------------------------------------
        diff = self.notInDB(srbZones, self.zones,
                              ['zone_id'], ['name'])
        for z in diff:
            print "adding zone: " + z.values['zone_id']
            dbZone = DBZone.add(self, z)
            self.zones.append(dbZone)
            resources = dbZone.getResources()
        
        for d in self.notInDB(srbDomains, self.domains, 
                                ['domain_desc'], ['name']):
            print "adding domain: " + d.values['domain_desc']
            dbDomain = DBDomain.add(self, d)
            self.domains.append(dbDomain)
        #---------------------------------------------------------------
        # Add resources within a zone... 
        # ALL zones and domain should be in the DB by now
        for z in self.zones:
            srbZone = wrapper.getZone(z.fields['name'])
            if(srbZone.values['zone_status'] == '1'):
                srbRsList = srbZone.getResources()
                dbRsList = z.getResources()
                for rs in self.notInDB(srbRsList.values(), dbRsList,
                                ['rsrc_name', 'phy_rsrc_name'],
                                ['rsrc_name', 'phy_rsrc_name']):
                    print "adding resource: " + rs.values['rsrc_name']
                    dbResource = DBResource.add(self, rs)
                    z.resources.append(dbResource)

        #---------------------------------------------------------------
        #Add users in domain  
        for dbDomain in self.domains:
            srbDomain = wrapper.getDomain(dbDomain.fields['name'])
            srbUsers = srbDomain.getAllUsers()
            userList = dbDomain.getAllUsers()

            for user in self.notInDB(srbUsers, userList, 
                                    ['user_name'], ['username']):
                print "adding user: " + user.values['user_name'] + \
                                     "@" + dbDomain.fields['name']
                dbUser = DBUser.add(self, user)
                dbDomain.users.append(dbUser)



def getFileTimestamp(filename):
    timestamp = file_name[len(zone_name) + 1:-4]
    date = timestamp[:10]
    time = timestamp[11:].replace('-', ':')
    return date + ' ' + time

#---------------------------------------------------------------------------
if(__name__ == "__main__"):
    if(len(sys.argv) < 2):
        print sys.argv[0] + " <path_to_xml_file_folder>"
        sys.exit(1)
    FOLDER = sys.argv[1]
    wrapper = SRBWrapper(LOCAL_ZONE)
    db = StatsDB()
    dbZones = []
    if(db.connectDB('dbhost', 'dbuser', 'dbpassword', 'dbname')):
        #connected ok!
        print "StatsDB.py: last modified 12th Nov 2008"
        db.initDB(wrapper)
        today = "-".join(map(repr, datetime.now().timetuple()[:3]))
        for zone_name in os.listdir(FOLDER):
            print "Processing zone: " + zone_name
            path = FOLDER + "/" + zone_name
            if(not(db.checkHasValuesToday(zone_name, today))):
                filenamesList = os.listdir(FOLDER + "/" + zone_name)
                filenamesList.sort()
                #since file names can be sorted by their datetime, the 
                #newest file must also be the last item in the directory
                #listing
                print "\tlist of files in directory is: " + `filenamesList`
                file_name = filenamesList[-1]
                print "\tprocessing lastest file: " + file_name
                path += "/" + file_name
                timestamp = getFileTimestamp(file_name)
                if(not (db.checkHasValuesXMLTimestamp(zone_name, timestamp))):
                    db.addLog(zone_name, timestamp, path)
                else:
                    #unlikely to get called... left in for debugging purposes
                    print """\tNo new files are found for zone - values with xml_timestamp of %s
                       has already been added to the database"""%(timestamp)
            
            else:
                print "\tValues for " + zone_name + " has already been updated today (" + today + ")"
        #always close the connection!
        db.close()        
    else:
        print "Cannot connect to db.... exiting..."
        sys.exit(2)

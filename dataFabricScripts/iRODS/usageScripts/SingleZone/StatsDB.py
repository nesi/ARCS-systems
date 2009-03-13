import os
import MySQLdb
import MySQLdb.cursors
from datetime import datetime
from StatsDBObjects import *
from statsXMLReader import *


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
    
    def __init___(self):
        self.zones = []
        
    def connectDB(self, _host, _user, _password, _dbName):
        super(StatsDB, self).connectDB(_host, _user, _password, _dbName)
        self.zones = getAll(self, DBZone)
        return True

    def getValue(self, list, field, value):
        for item in list:
            if(item.fields[field] == value):
                return item
        return None

    def getZone(self, zoneName):
        return self.getValue(self.zones, 'name', zoneName)

    def getGroup(self, groupName, zoneName):
        z = self.getZone(zoneName)
        return z.getGroup(groupName)

    def addLog(self, processZone, xml_timestamp, filename):

        reader = StatsXMLReader(filename)
        reader.getDBObjects() 

        print "\tinserting user usage values"
        for usr in reader.userList:
            uList = []
            zName = usr.map['zone'].encode('utf8')
            uName = usr.map['name']

            zone = self.getZone(zName)
            if (zone == None):
                zone = DBZone.add(self, zName)
                self.zones.append(zone)
            uList.append(zName)
            uList.append(uName)
            user = (self.getZone(usr.map['zone'])).getUser(usr.map['name'])
            if (user == None):
                user =  DBUser.add(self, uList)
             
            for rsc in usr.resourceList:
                (resourceName, amount, count) = rsc
                print resourceName, amount, count
                dbResource = self.getZone(zName).getResource(resourceName)
                if dbResource == None:
                   rList = []
                   rList.append(zName)
                   rList.append(resourceName)
                   dbResource = DBResource.add(self, rList)
                DBUseLogEntry.addUser(self, user, dbResource, (long)(amount[:-2]), (long)(count), xml_timestamp)

        print "\tinserting group usage values"
        for grp in reader.groupList:
            group = self.getGroup(grp.map['name'], grp.map['zone'])
            if(group == None):
                group = DBGroup.add(self, grp.map['name'], grp.map['zone'])
            for rsc in grp.resourceList:
                (resourceName, amount, count) = rsc
                dbResource = self.getZone(zone.fields['name']).getResource(resourceName)
                DBUseLogEntry.addGroup(self, group, dbResource, (long)(amount[:-2]), (long)(count), xml_timestamp)
       
    def checkHasValuesToday(self, zone, today):
        sql = """SELECT timestamp FROM use_log WHERE resource_id 
                IN (SELECT resources.id FROM resources, zones WHERE 
                resources.zone_id = zones.id and 
                zones.name = '%s') and
                DATE(timestamp) = DATE('%s')
                LIMIT 1"""%(zone,today) 

        row = self.executeStatement(sql)
        if(row == None):
            return False
        else:
            return True

    def checkHasValuesXMLTimestamp(self, zone, timestamp):
        sql = """SELECT timestamp FROM use_log WHERE resource_id
                IN (SELECT resources.id FROM resources, zones WHERE
                resources.zone_id = zones.id and
                zones.name = '%s') and
                xml_timestamp = '%s'
                LIMIT 1"""%(zone, timestamp)

        row = self.executeStatement(sql)
        if(row == None):
            return False
        else:
            return True


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
    db = StatsDB()
    if(db.connectDB('DB_Host', 'DB_User_Name', 'DB_User_Password', 'DB_Name')):
        today = "-".join(map(repr, datetime.now().timetuple()[:3]))
        for zone_name in os.listdir(FOLDER):
            print "Processing zone: " + zone_name
            path = FOLDER + "/" + zone_name 
            if(not(db.checkHasValuesToday(zone_name, today))):
                filenamesList = os.listdir(FOLDER + "/" + zone_name)
                if(len(filenamesList) > 0):
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
                    print "No files found in " + FOLDER + "/" + zone_name + "... skipping zone"
            else:
                print "\tValues for " + zone_name + " has already been updated today (" + today + ")"
        #always close the connection!
        db.close()        
    else:
        print "Cannot connect to db.... exiting..."
        sys.exit(2)

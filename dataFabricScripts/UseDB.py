import MySQLdb
import MySQLdb.cursors
from SRBResult import *
from SRBWrapper import *
#---static goodness
class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable

def getAll(db, Type):
        sql = "SELECT * FROM " + Type.tableName
        records = db.executeStatement(sql)
        results = []
        if(records <> None):
            for r in records:
                results.append(Type(db, r))
        return results
#------------------------------------------------------------
#Generic functions that all "object" in the database should
#have
class DBObject(object):
    tableName = ""
    def __init__(self, _db, record = None):
        self.tableName = ""
        self.db = _db
        self.fields = {}
        if(record <> None):
            self.processRows(record)
        else:
            self.fields['id'] = -1

    def valueToString(self, val):
        if(isinstance(val, long)):
            return repr(val)[:-1]
        else:
            return repr(val)

    def insertSelf(self):
        if(self.fields['id'] == -1):
            #can't add id of -1!!
            keyList = []
            valueList = []

            for key in [k for k in self.fields.keys() if (k <> 'id')]:
                #just to make sure the keys are in the same order
                #as the values...
                keyList.append(key)
                valueList.append(self.fields[key])

            sql = "INSERT INTO " + self.__class__.tableName + " ("
            sql += ",".join(keyList)
            sql += ") "
            sql += " VALUES (" + ",".join(map(self.valueToString, valueList))
            sql += ")"
            self.fields['id'] = self.db.executeInsert(sql)
        return self.fields['id']
        
    def processRows(self, record):
        #override this method if you need to do 
        #something special when interpreting row results
        self.fields = {}
        for col, val in record.iteritems():
            self.fields[col] = val
#------------------------------------------------------------
class DBUser(DBObject):
    tableName = "users"

    def __init__(self, _db, _record = None):
        super(DBUser, self).__init__(_db, _record)
        

    def add(db, srbUser):
        user = DBUser(db)
        zone = db.getZone(srbUser.values['zone_id'])
        domain = db.getDomain(srbUser.values['domain_desc'])
        user.fields['username'] = srbUser.values['user_name']
        user.fields['domain_id' ] = domain.fields['id']
        user.fields['zone_id'] = zone.fields['id']
        user.insertSelf()
        return user

    #--untested
    def getLogs(self, start, end):
        startStr = "-".join(start.timetuple()[:3]) + " " + \
                        ":".join(start.timetuple[3:6])
        
        endStr = "-".join(end.timetuple()[:3]) + " " + \
                        ":".join(end.timetuple[3:6])
        sql = """SELECT * FROM %s WHERE user_id = %s timestamp >= '%s' AND
                timestamp <= '%s'""" % \
                (repr(self.fields['id'])[:-1], DBUser.tableName, startStr, endStr)

        records = db.executeStatement(sql)
        if(records == None):
            return []
        result = []
        for row in records:
            result.append(DBUserLogEntry(db, row))
        return result
    
    add = Callable(add)

#------------------------------------------------------------
class DBDomain(DBObject):
    tableName = "domains"
    def __init__(self, _db, _record = None):
        super(DBDomain, self).__init__(_db, _record)
        self.users = []
        if(_record <> None):
            self.users = self.getAllUsers()

    def getUser(self, username):
        for user in self.users:
            if(user.fields['username'] == username):
                return user
        return None

    def getDomain(db, _domain_desc):
        sql = "SELECT * FROM %s WHERE domain_desc = '%s'" %\
                (DBDomain.tableName,  _domain_desc)
        row = db.executeStatement(sql)
        if(row == None):
            return None
        newDomain = DBDomain(db, row)
        return newDomain

    def getAllUsers(self):
        if(len(self.users) == 0):
            sql = "SELECT * FROM %s WHERE domain_id = %d" %\
                 (DBUser.tableName, self.fields['id'])
            records = db.executeStatement(sql)
            if(records == None):
                return []
            else:
                results = []
                for row in records:
                    user = DBUser(db, row)
                    results.append(user)
                self.users = results
        return self.users

    def add(db, srbDomain):
        domain = DBDomain(db)
        domain.fields['name'] = srbDomain.values['domain_desc']
        domain.insertSelf()
        return domain

    add = Callable(add)
#------------------------------------------------------------
class DBResource(DBObject):
    tableName = "resources"
    def __init__(self, db, _record = None):
        super(DBResource, self).__init__(db, _record)
        if(_record <> None):
            self.type = db.getResourceTypeById(_record['rsrc_type_id'])

    def getResourceInZone(db, _zone_id):
        sql = """SELECT * FROM %s WHERE zone_id = %d """ % \
                (DBResource.tableName, _zone_id)
        rows = db.executeStatement(sql)
        if(rows == ()):
            return None
        results = []
        for record in rows:
            dbr = DBResource(db, record, _domain, _zone)
            results.append(dbr)
        return results

    def add(db, srbResource):
        newResource = DBResource(db)
        dom = db.getDomain(srbResource.values['domain_desc'])
        zone = db.getZone(srbResource.values['zone_id'])
        type = db.getResourceType(srbResource.values['rsrc_typ_name'])
        newResource.fields['rsrc_name'] = srbResource.values['rsrc_name']
        newResource.fields['rsrc_type_id'] = type.fields['id']
        newResource.fields['phy_rsrc_name'] = srbResource.values['phy_rsrc_name']
        newResource.fields['zone_id'] = zone.fields['id']
        newResource.fields['domain_id'] = dom.fields['id']
        newResource.type = type
        newResource.insertSelf()
        return newResource
       
    add = Callable(add) 
#------------------------------------------------------------
class DBResourceType(DBObject):
    tableName = "rsrc_types"
    def __init__(self, _db, _record = None):
        super(DBResourceType, self).__init__(_db, _record)
 
    def add(db, srbResult):
        rs = DBResourceType(db)
        rs.fields['name'] = srbResult.values['rsrc_typ_name']
        rs.insertSelf()
        return rs

    add = Callable(add)

#------------------------------------------------------------
class DBUseLogEntry(DBObject):
    tableName = "use_log"
    def __init__(self, _db, _record = None):
        super(DBUseLogEntry, self).__init__(_db, _record)


    def add(db, user, resource, amount):
        newRecord = DBUseLogEntry(db)
        newRecord.fields['user_id'] = user.fields['id']
        newRecord.fields['resource_id'] = resource.fields['id']
        newRecord.fields['amount'] = amount
        newRecord.insertSelf()
        return newRecord
    
    add = Callable(add)

#------------------------------------------------------------
class DBZone(DBObject):
    tableName = "zones"
    def __init__(self, _db, _record = None):
        super(DBZone, self).__init__(_db, _record)
        self.resources = []
        if(_record <> None):
            self.resources = self.getResources()

    def getZone(db, _zone_id):
        sql = "SELECT * FROM %s WHERE zone_id = '%s'" % \
                (DBZone.tableName, _zone_id)
        row = db.executeStatement(sql)
        if(row == None):
            return None
        else:
            newZone = DBZone(db, row)
            return newZone

    def add(db, srbZone):
        zone = DBZone(db)
        zone.fields['name'] = srbZone.values['zone_id']
        zone.insertSelf()
        return zone

    def getResources(self):
        sql = "SELECT * FROM %s WHERE zone_id = %d" % \
                (DBResource.tableName, self.fields['id'])

        records = db.executeStatement(sql)
        if(records == None):
            return []
        else:
            results = []
            for r in records:
                rs = DBResource(db, r)
                results.append(rs)
            return results    

    def getResource(self, _rsName, _phyName):
        for rs in self.resources:
            if((rs.fields['rsrc_name'] == _rsName) and
                (rs.fields['rsrc_phy_name'] == _phyName)):
                return rs
        return None        
    add = Callable(add)

#------------------------------------------------------------
class UseDB:
    def __init___(self):
        self.zones = []
        self.domains = []
        self.resourceTypes = []
        
    def connectDB(self, _host, _user, _password, _dbName):
        try:
            self.conn = MySQLdb.connect(host = _host,
                    user = _user, passwd = _password, 
                    db = _dbName,
                    cursorclass = MySQLdb.cursors.DictCursor)
            #must get atomic types first
            self.resourceTypes = getAll(self, DBResourceType)
            self.zones = getAll(self, DBZone)
            self.domains = getAll(self, DBDomain)
            return True
        except MySQLdb.Error, e:
            print "Error with connecting to DB: ", `e`
            self.conn.close()
            return False

    def executeStatement(self, sql):
        results = []
        try:
            try:
                cursor = self.conn.cursor()
                cursor.execute(sql)
                rows = cursor.fetchall()
                
                if(rows == ()):
                    return None
                else:
                    for row in rows:
                        results.append(row)
                if(len(results) == 0):
                    #Makes it easier to test...
                    return None
                return results
            except MySQLdb.Error, e:
                print "Error with executing SQL statement: " + sql + ", " + `e`
                return None
        finally:
            cursor.close()

    def executeInsert(self, sql):
        try:
            try:
                cursor = self.conn.cursor()
                cursor.execute(sql)
                self.conn.commit()
                cursor.close()
                return cursor.lastrowid
            except MySQLdb.Error, e:
                print "Error with executing SQL statement: " + sql
                print `e`
                #to indivate something went very very wrong...
                return -1
        finally:
            cursor.close()
    
    def close(self):
        self.conn.close()
   
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

    def addLog(self, wrapper):
        totalsList = wrapper.getTotalUsageByResourceUserZone()
        for userAtDomain, value in totalsList.iteritems():
            split = userAtDomain.split("@")            
            domain = self.getDomain(split[1])
            user = domain.getUser(split[0])
            (amount, zoneGroup) = value
            for z, uses in zoneGroup.iteritems():
                zone = self.getZone(z)
                srbZone = wrapper.getZone(z)
                for resource in zone.getResources():
                    if(resource.type.fields['name'] <> 'logical'):
                        #we don't add anything in for logical,
                        #since that's an aggregate of physical 
                        #resources anyway...
                        srbRs = srbZone.getResource(resource.fields['rsrc_name'])
                        amount = srbRs.getUsedAmount(uses)
                        DBUseLogEntry.add(self, user, resource, (long)(amount))     
                   
    def initDB(self, wrapper):
        """Grabs values out of (or add to) DB for everything 
            except for log entires"""
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
#---------------------------------------------------------------------------
if(__name__ == "__main__"):
    wrapper = SRBWrapper('ngdev2.its.utas.edu.au')
    db = UseDB()
    dbZones = []
    #if(db.connectDB('ngsyslog.hpcu.uq.edu.au', 'srb', 'srblog', 'srbUsage')):
    if(db.connectDB('host', 'user', 'password', 'dbname')):
        #connected ok!
        db.initDB(wrapper)
        db.addLog(wrapper)

        #always close the connection!
        db.close()        
    else:
        print "Cannot connect to db.... exiting..."
        sys.exit(2)

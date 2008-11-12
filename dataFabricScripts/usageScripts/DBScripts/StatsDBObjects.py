import sys
import MySQLdb
import MySQLdb.cursors
from SRBResult import *
from SRBWrapper import *
from StatsDBConnector import StatsDBConnector

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

    def setValues(self, _fields):
        self.fields = _fields

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

    add = Callable(add)

class DBGroup(DBObject):
    tableName = "groups"
    def __init__(self, _db, _record = None):
        super(DBGroup, self).__init__(_db, _record)

    def add(db, _name, _zoneName):
        grp = DBGroup(db)
        zone = db.getZone(_zoneName)
        grp.fields['zone_id'] = zone.fields['id']
        grp.fields['name'] = _name.encode('utf8')
        grp.insertSelf()
        return grp

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
            records = self.db.executeStatement(sql)
            if(records == None):
                return []
            else:
                results = []
                for row in records:
                    user = DBUser(self.db, row)
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
            self.type = self.db.getResourceTypeById(_record['rsrc_type_id'])

    def getResourceInZone(db, _zone_id):
        sql = """SELECT * FROM %s WHERE zone_id = %d """ % \
                (DBResource.tableName, _zone_id)
        rows = self.db.executeStatement(sql)
        if(rows == ()):
            return None
        results = []
        for record in rows:
            dbr = DBResource(self.db, record, _domain, _zone)
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


    def addUser(db, user, resource, amount, count, xml_timestamp):
        newRecord = DBUseLogEntry(db)
        newRecord.fields['user_id'] = user.fields['id']
        newRecord.fields['resource_id'] = resource.fields['id']
        newRecord.fields['amount'] = amount
        newRecord.fields['num_files'] = count   
        newRecord.fields['xml_timestamp'] = xml_timestamp
        newRecord.insertSelf()
        return newRecord

    def addGroup(db, group, resource, amount, count, xml_timestamp):
        newRecord = DBUseLogEntry(db)
        newRecord.fields['group_id'] = group.fields['id']
        newRecord.fields['resource_id'] = resource.fields['id']
        newRecord.fields['amount'] = amount
        newRecord.fields['num_files'] = count   
        newRecord.fields['xml_timestamp'] = xml_timestamp
        newRecord.insertSelf()
        return newRecord

    addUser = Callable(addUser)
    addGroup = Callable(addGroup)

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

        records = self.db.executeStatement(sql)
        if(records == None):
            return []
        else:
            results = []
            for r in records:
                rs = DBResource(self.db, r)
                results.append(rs)
            return results
    
    def getGroup(self, grpName):
        sql = "SELECT * FROM %s WHERE zone_id = %d and name='%s'" % \
                (DBGroup.tableName, self.fields['id'], grpName)
        records = self.db.executeStatement(sql)
        if(records == None):
            return None
        else:
            newGroup = DBGroup(self.db, records[0])
            return newGroup

    def getResource(self, _rsName, _phyName):
        for rs in self.resources:
            if((rs.fields['rsrc_name'] == _rsName) and
                (rs.fields['phy_rsrc_name'] == _phyName)):
                return rs
        return None
    add = Callable(add)


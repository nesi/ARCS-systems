import sys
import MySQLdb
import MySQLdb.cursors
from StatsDBConnector import StatsDBConnector

class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable

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

    def add(db, irodsUser):
        user = DBUser(db)
        zone = db.getZone(irodsUser[0])
        user.fields['username'] = irodsUser[1].encode('utf8')
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
class DBResource(DBObject):
    tableName = "resources"
    def __init__(self, db, _record = None):
        super(DBResource, self).__init__(db, _record)

    def getResourceInZone(db, _zone_id):
        sql = """SELECT * FROM %s WHERE zone_id = %d """ % \
                (DBResource.tableName, _zone_id)
        rows = self.db.executeStatement(sql)
        if(rows == ()):
            return None
        results = []
        for record in rows:
            dbr = DBResource(self.db, record, _zone)
            results.append(dbr)
        return results

    def add(db, irodsResource):
        newResource = DBResource(db)
        print  irodsResource
        zone = db.getZone(irodsResource[0])
        newResource.fields['rsrc_name'] = irodsResource[1].encode('utf8')
        newResource.fields['zone_id'] = zone.fields['id']
        newResource.insertSelf()
        return newResource

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
        self.users = []
        if(_record <> None):
            self.resources = self.getResources()
            self.users = self.getAllUsers()

    def getZone(db, _zone_id):
        sql = "SELECT * FROM %s WHERE zone_id = '%s'" % \
                (DBZone.tableName, _zone_id)
        row = db.executeStatement(sql)
        if(row == None):
            return None
        else:
            newZone = DBZone(db, row)
            return newZone

    def add(db, irodsZone):
        zone = DBZone(db)
        zone.fields['name'] = irodsZone
        zone.insertSelf()
        return zone

    def getResources(self):
        sql = "SELECT * FROM %s WHERE zone_id = %d" % \
                (DBResource.tableName, self.fields['id'])
        records = self.db.executeStatement(sql)
        if(records == None):
            return None
        else:
            results = []
            for r in records:
                rs = DBResource(self.db, r)
                results.append(rs)
            return results
    
    def getUser(self, username):  
        for user in self.users:                
            if(user.fields['username'] == username):    
                return user
        return None

    def getAllUsers(self):
        if(len(self.users) == 0):
            sql = "SELECT * FROM %s WHERE zone_id = %d" %\
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

    def getGroup(self, grpName):
        sql = "SELECT * FROM %s WHERE zone_id = %d and name='%s'" % \
                (DBGroup.tableName, self.fields['id'], grpName)
        records = self.db.executeStatement(sql)
        if(records == None):
            return None
        else:
            newGroup = DBGroup(self.db, records[0])
            return newGroup

    def getResource(self, _rsName):
        sql = "SELECT * FROM %s WHERE zone_id = %d" % \
                (DBResource.tableName, self.fields['id'])
        records = self.db.executeStatement(sql)
        if(records == None):
            return None  
        else: 
            for rs in records:
               rsDB = DBResource(self.db, rs)  
               if((rsDB.fields['rsrc_name'] == _rsName)):
                     return rsDB
    add = Callable(add)


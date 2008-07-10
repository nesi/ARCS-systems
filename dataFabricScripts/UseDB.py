import MySQLdb
from SRBResult import *
from SRBWrapper import *
#---static goodness
class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable

#Reconsistutes records as DBObjects
def parse(db, row, CreatFunc):
    if(row == None):
        return None

    result = []
    rows = sql.fetchAll()
    for record in rows:
        result.append(CreateFunc(db, record))
    return result

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
            sql += " VALUES (" + ",".join(map(repr, valueList))
            sql += ")"
            self.fields['id'] = self.db.executeInsert(sql)
        return self.fields['id']
        
    def getLinkedObjectsById(self, TargetClasses):
        """Grabs all instances of TargetClass which references *this* 
            object.  Note that this ONLY WORKS if and only if there is
            a single foreign key.  e.g. get all domain in a zone,
            where this instance is a zone, and the domain table 
            contains a key to zone, with the name zone_id."""
        list = []
                                        #all referenced id fields are name
                                        #foreign tablename (minus plural) + _id
        sql = "SELECT * FROM %s WHERE " + self.TableName[:-1] + "_id = '%d'"% \
                (TargetClass.tableName, self.fields['id'])

        rows = self.db.executeStatement(sql)        
        list = parse(self.db, rows, lambda x, y: TargetClass(x, y, self))
        return list
    
    def processRows(self, record):
        #override this method if you need to do 
        #something special when interpreting row results
        self.fields = {}
        for col in record:
            self.fields[col[0]] = col[1]
#------------------------------------------------------------
class DBUser(DBObject):
    tableName = "users"

    def __init__(self, _db, _record = None, _domain = None, _zone = None):
        super(DBUser, self).__init__(_db, _record)
        self.domain = _domain
        self.zone = _zone

    def getUser(db, username, domain_name):
        dom = DBDomain.getDomain(domain_name)
        if(dom == None):
            return None

        sql = """SELECT * FROM %s WHERE username = '%s' AND
                domain_id = %d""" % (username, dom.fields['id'])

        row = db.executeStatement(sql)
        user = DBUser(db, row, dom)
        return user
        
#------------------------------------------------------------
class DBDomain(DBObject):
    tableName = "domain"
    def __init__(self, _db, _record = None):
        super(DBUser, self).__init__(_db, _record)

    def getUsersInDomain(self):
        users = getLinkedObjectsById(DBUser)

    def getDomain(db, _domain_desc):
        sql = "SELECT * FROM %s WHERE domain_desc = '%s'" %\
                (DBDomain.tableName,  _domain_desc)
        row = db.executeStatement(sql)
        if(row == None):
            return None
        newDomain = DBDomain(db, row)
        return newDomain

    def getAll(db):
        list = []
        sql = "SELECT * FROM " + DBDomain.tableName
        records = db.executeStatement(sql)
        if(records == ()):
            return None
        else:
            for rec in records:
                list.append(DBDomain(db, rec))
        return list

        

    getAll = Callable(getAll)

#------------------------------------------------------------
class DBResource(DBObject):
    def __init__(self, _db, _record = None, _domain = None, 
                    _zone = None):
        super(DBResource, self).__init__(db, _record)
        self.domain = _domain
        self.zone = _zone

    def getResourceInZone(db, _zone, _domain):
        sql = """SELECT * FROM %s WHERE zone_id = %d 
                AND domain_id = %d""" % \
                (_zone.columns['id'], _domain.columns['id'])
        rows = db.executeStatement(sql)
        if(rows == ()):
            return None
        results = []
        for record in rows:
            dbr = DBResource(db, record, _domain, _zone)
            results.append(dbr)
        return results
#------------------------------------------------------------
class DBZone(DBObject):
    tableName = "zones"
    def __init__(self, _db, _record = None):
        super(DBZone, self).__init__(_db, _record)

    def getZone(db, _zone_id):
        sql = "SELECT * FROM zones WHERE zone_id = '%s'" % _zone_id
        row = db.executeStatement(sql)
        if(row == None):
            return None
        else:
            newZone = DBZone(db, row)
            return newZone

    def addZone(db, _new_zone_name):
        dbZone = DBZone(db)
        dbZone.fields['zone_id'] = z.values['zone_id']
        dbZone.insertSelf()
        return dbZone

    def addIfNotExist(db, _new_zone_name):
        z = DBZone.getZone(db, _new_zone_name)
        if(z == None):
            return addZone(db, _new_zone_name)

    def getAll(db):
        list = []
        sql = "SELECT * FROM " + DBZone.tableName
        records = db.executeStatement(sql)
        if(records == ()):
            return None
        else:
            for rec in records:
                list.append(DBZone(db, rec))
        return list

    getZone = Callable(getZone)
    addZone = Callable(addZone)
    addIfNotExist = Callable(addIfNotExist)
    getAll = Callable(getAll)

#------------------------------------------------------------
class UseDB:
    def __init___(self):
        self.conn = self.connectDB()
        self.zones = DBZone.getAll(self.conn)
        self.domains = DBDomain.getAll(self.conn)
        

    def connectDB(self, _host, _user, _password, _dbName):
        try:
            self.conn = MySQLdb.connect(_host,
                    _user, _password, _dbName)
            return True
        except MySQLdb.Error, e:
            print "Error with connecting to DB: ", e
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
                return results
            except MySQLdb.Error, e:
                print "Error with executing SQL statement: " + sql + ", " + e
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
                return cursor.insert_id()
            except:
                print "Error with executing SQL statement: " + sql
                return None
        finally:
            cursor.close()
    
    def close(self):
        self.conn.close()

    def getZone(self, zoneName):
        for z in self.zones:
            if(z.fields['zone_id'] == zoneName):
                return z
        return None

    def getDomain(self, domainName):
        for d in self.domains:
            if(d.fields['domain_desc'] == domainName):
                return d
        return None

    def initDB(self, wrapper):
        """Grabs values out of (or add to) DB for everything 
            except for log entires"""
        srbZones = wrapper.getKnownZones()
        srbDomains = wrapper.getKnownDomains()
        #---------------------------------------------------------------
        for d in srbDomains:
            dbDomain = self.getDomain(d.values['domain_desc'])
            if(dbDomain == None):
                dbDomain = DBDomain.addIfNotExist(self.conn, d.values['domain_desc'])
                self.domains.append(dbZone)
        #---------------------------------------------------------------
        for z in srbZones:
            dbZone = self.getZone(z.values['zone_id'])
            if(dbZone == None):
                dbZone = DBZone.addIfNotExist(self.conn, z.values['zone_id'])
                self.zones.append(dbZone)
            resources = dbZone.getResources()
            # ALL zones and domain should be in the DB by now
            #---------------------------------------------------------------
            userList = z.getUsers()
            #for user in userList:
            #    dbUser = DBUser.addIfNotExit(self.conn, 
            #                                self.getDomain(user.values['domain_desc']), 
            #                                self.getZone(user.values['zone_id'])
                 
               

#---------------------------------------------------------------------------
if(__name__ == "__main__"):
    wrapper = SRBWrapper('localdomain')
    db = UseDB()
    dbZones = []
    if(db.connectDB('host', 'user', 'password', 'dbname')):
        #connected ok!
        #db.initDB(wrapper)a
        print "connected!"
        db.close()        
    else:
        print "Cannot connect to db.... exiting..."
        sys.exit(2)

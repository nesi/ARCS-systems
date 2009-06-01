
#!/usr/bin/python
# dbOps.py: fetching sharedToken of each user from ICAT Table r_user_main and writing them to Table users of MySQL DB - irodsUsage   
# The script also provides other operations to DB, i.e deletion
# You can modify it to meet your needs

# The script requires the following installations: 
# (1) postgresql-python.i386 package. Run:
#     yum install postgresql-python.i386
# (2) MySQL-python.i386 package. Run:
#     yum install MySQL-python.i386

import pgdb, sys, re, types
import MySQLdb
import MySQLdb.cursors


class table:
    
    _closed = True     

    def __init__(self, db, name):

            self.db = db
            self.name = name
            self.dbc = None
            self._new_cursor()
            self._search = ""
            self._sort = ""
            self._closed = False

    def sort(self, method):
		self._sort = ""
		if method: self._sort = "order by %s" % (method)

    def search(self, method):

            self._search = ""
	    if method: 
                     self._search = "%s" % (method)
    
    def _new_cursor(self):
            
            if self.dbc:
                    self.dbc.close()
            self.dbc = self.db.obj.cursor()

    def _query(self, q, data=None):

            if not self.dbc:
                    self._new_cursor()
            self.dbc.execute(q, data)

    def __getitem__(self, item):

            q = "select * from %s %s %s" % (self.name, self._search, self._sort)
            if isinstance(item, types.StringType):
                    q = "select %s from %s %s %s" % (item, self.name, self._search, self._sort)
                    self._query(q)
                    return self.dbc.fetchall()
            elif isinstance(item, types.IntType):
		    if item < 0:  
			item = len(self) + item
			if item < 0:
				raise IndexError, "too negative"
		    q = q + " limit 1 offset %s" % (item)
		    self._query(q)
		    return self.dbc.fetchone()
            else:
                    raise IndexError, "unknown type"

    def insert(self, *row):

           stm = ("%s," * len(row))[:-1]
           q = "insert into %s values %s" % (self.name, stm)
           self._query(q, row)
 
    def update(self, modiCol, item, whereCol):
           
           q = "update %s set %s='%s' where %s='%s'" % (self.name, modiCol, item, whereCol, self._search)
           self._query(q)
 
    def delete(self):
           
           q = "delete from %s %s" % (self.name, self._search)
           self._query(q)

    def __iter__(self):
            self._new_cursor()
            q = "select * from %s %s" % (self.name, self._search)
            self._query(q)
            return self

    def next(self):
            r = self.dbc.fetchone()
            if not r:
                    self._new_cursor()
                    raise StopIteration
            return r

    def __len__(self):
		self._query("select count(*) from %s %s" % (self.name, self._search))
		r = int(self.dbc.fetchone()[0])
		return r

    def close(self):
            if not self._closed:
                    try:
                         self.dbc.close()
                    except Exception:
                         pass
            self._closed = True


class db:
     
     _closed = True

     def __init__(self, dbType, **args):
           self._tables = {}
           self._close = False
           self.dbType = dbType
	   if args:
		 self.connect(**args)

     def connect(self, **args):
		self.obj = self.dbType.connect(**args)

     def commit(self):
                self.obj.commit()

     def close(self):
           if not self._closed:
                try:
                   self.obj.close()
                except Exception:
                   pass
                   self._closed = true

def main():

    dbICAT = db(pgdb, dsn = 'localhost:ICAT:rods:PASSWORD')
    dbUsage = db(MySQLdb, user='DB User Name',passwd='PASSWORD',host='MySQL Server Host Name',db='MySQL DB NAME')

    src = table(dbICAT, 'r_user_main')        
    userInfo1 = src["user_name, user_info"]
    userDict = {}
    for row in userInfo1:
        if row[1] <> None:
           userDict[row[0]] = re.sub(r'</?ST>', '', row[1])   

    dest = table(dbUsage, 'users')
    userInfo2 = dest["username, sharedToken"]
   
    for row in userInfo2:
        if len(row[1]) == 0:
           if userDict.has_key(row[0]):
              userName = row[0]
              sharedToken = userDict.get(row[0])
              dest.search(userName)
              dest.update('sharedToken', sharedToken, 'username')
            
    dbUsage.commit()
    dbICAT.close()
    dbUsage.close()
 
if __name__=="__main__":
    sys.exit(main())




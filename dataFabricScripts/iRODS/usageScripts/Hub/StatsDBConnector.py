import MySQLdb
import MySQLdb.cursors
from StatsDBConnector import *

class Callable:
    def __init__(self, anycallable):
        self.__call__ = anycallable
#------------------------------------------------------------
class StatsDBConnector(object):
    def connectDB(self, _host, _user, _password, _dbName):
        try:
            self.conn = MySQLdb.connect(host = _host,
                    user = _user, passwd = _password,
                    db = _dbName,
                    cursorclass = MySQLdb.cursors.DictCursor)
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
                return -1
        finally:
            cursor.close()

    def close(self):
        self.conn.close()



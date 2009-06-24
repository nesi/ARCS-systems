#!/usr/bin/python
import pgdb, sys
import os
import xml.dom.minidom

# ------------------------------------------------------------
# Assuming:
#    - the DB name is ICAT
#    - the owner of ICAT is rods
# ------------------------------------------------------------

class StatsExporter:
    def __init__(self, _zone):

        self.pgAuth = os.popen("cat ~/.pgpass").readlines()[0].split(':')
        self.dbConn = pgdb.connect(host=self.pgAuth[0] + ':'+ self.pgAuth[1], user=self.pgAuth[3], database=self.pgAuth[2], password=self.pgAuth[4][:-1])
        self.doc = xml.dom.minidom.Document()
        self.root = self.doc.createElement('usages')
        self.doc.appendChild(self.root)
        self.zone = _zone
        zoneNode = self.createChild(self.root, 'zone', self.zone)
        self.cursor = None

    def doQuery(self, query):
        newCursor = self.dbConn.cursor()
        newCursor.execute(query)
        return newCursor

    def createChild(self, parent, childName, childValue = None):
        child = self.doc.createElement(childName)
        if(childValue <> None):
            childTxt = None
            try:
                childTxt = self.doc.createTextNode(childValue)
            #possibly dogey...
            except TypeError:
                childTxt = self.doc.createTextNode(repr(childValue))
            child.appendChild(childTxt)
        parent.appendChild(child)
        return child

    def close(self):
        self.dbConn.close()

    #list name is assumed to be a plural...
    def processResults(self, listName, rows):
        elementList = self.createChild(self.root, listName)
        lastUser = None
        resourcesList = None
        for row in rows:
            curUser = row[0] + "@" + row[1]
            if(curUser <> lastUser):
                element = self.createChild(elementList, listName[:-1])
                self.createChild(element, 'name', row[0])
                self.createChild(element, 'zone', row[1])
                resourceList = self.createChild(element, 'resources')
                lastUser = curUser
            resource = self.createChild(resourceList, 'resource')
            self.createChild(resource, 'id', row[2])
            self.createChild(resource, 'amount', row[3])
            self.createChild(resource, 'count', repr(row[4])[:-1])
            curUser = element

    def addRecordToDoc(self, query, listName):
        cur = self.doQuery(query)
        results = cur.fetchall()
        cur.close()
        self.processResults(listName, results)

# ---------------------------------------------------------------------------------- 
# Assuming that we still follow the convention we have used in SRB:
#   - associating the amount used/number of files with a group-based projects folder
# ----------------------------------------------------------------------------------

    def work(self):

        query = """SELECT dataTable.data_owner_name, dataTable.data_owner_zone,
                    dataTable.resc_name,
                    SUM(dataTable.data_size), COUNT(dataTable.data_id)
                    FROM
                    (SELECT object_id FROM r_objt_access WHERE access_type_id = 1200
                    EXCEPT  
                    (SELECT object_id FROM r_objt_access WHERE user_id IN
                    (SELECT user_id FROM r_user_main WHERE user_type_name = 'rodsgroup'))) AS accessTable
                    INNER JOIN
                    (SELECT data_id, data_size, data_owner_name, data_owner_zone, resc_name FROM r_data_main ) AS dataTable
                    ON
                    accessTable.object_id = dataTable.data_id
                    GROUP BY dataTable.data_owner_name, dataTable.data_owner_zone, dataTable.resc_name
                    ORDER BY dataTable.data_owner_name, dataTable.data_owner_zone, dataTable.resc_name"""
        self.addRecordToDoc(query, 'users')

        query = """SELECT userTable.user_name, dataTable.data_owner_zone,
                    dataTable.resc_name,
                    SUM(dataTable.data_size), COUNT(dataTable.data_id)
                    FROM
                    r_user_main as userTable,
                    r_objt_access as accessTable,
                    r_data_main as dataTable
                    WHERE
                    userTable.user_type_name = 'rodsgroup' AND
                    userTable.user_id = accessTable.user_id AND
                    accessTable.object_id = dataTable.data_id 
                    GROUP BY userTable.user_name, dataTable.data_owner_zone, dataTable.resc_name
                    ORDER BY userTable.user_name, dataTable.data_owner_zone, dataTable.resc_name"""
        self.addRecordToDoc(query, 'projects')

    def prettyPrint(self):
        print self.doc.toprettyxml(encoding='utf-8')

if(__name__ == "__main__"):
    #getResources()
    lines = os.popen("cat ~/.irods/.irodsEnv|grep 'irodsZone'").readlines()
    if(len(lines) == 1):
        zone = lines[0].split("'")[1]
        exporter = StatsExporter(zone)
        exporter.work()
        exporter.prettyPrint()
        exporter.close()
    #getProjectUsage()

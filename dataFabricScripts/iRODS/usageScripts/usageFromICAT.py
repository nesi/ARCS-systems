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
        self.dbConn = pgdb.connect(dsn = 'localhost:ICAT:rods')
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
        query = """select userTable.user_name, userTable.zone_name,
                    resourceTable.resc_name, 
                    sum(dataTable.data_size), count(dataTable.data_id)
                    from
                    r_user_main as userTable,
                    r_data_main as dataTable,
                    r_coll_main as collTable,
                    r_resc_main as resourceTable
                    where
                    dataTable.data_owner_name = userTable.user_name and
                    dataTable.data_owner_zone = userTable.zone_name and
                    (collTable.coll_name like '/%/home/%' and  not (collTable.coll_name like '/%/projects/%')) and
                    dataTable.coll_id = collTable.coll_id and
                    resourceTable.resc_name = dataTable.resc_name 
                    group by userTable.user_name, userTable.zone_name,  resourceTable.resc_name
                    order by userTable.user_name, userTable.zone_name, resourceTable.resc_name""" 
        self.addRecordToDoc(query, 'users')

        query = """select userTable.user_name, userTable.zone_name,
                    resourceTable.resc_name,
                    sum(dataTable.data_size), count(dataTable.data_id)
                    from
                    r_user_main as userTable,
                    r_objt_access as accessTable,
                    r_data_main as dataTable,
                    r_resc_main as resourceTable
                    WHERE
                    userTable.user_type_name = 'rodsgroup' and
                    userTable.user_id = accessTable.user_id and
                    accessTable.object_id = dataTable.data_id and
                    dataTable.resc_name = resourceTable.resc_name and
                    dataTable.data_owner_zone = userTable.zone_name
                    group by userTable.user_name, userTable.zone_name, resourceTable.resc_name
                    order by userTable.user_name, userTable.zone_name, resourceTable.resc_name"""
        self.addRecordToDoc(query, 'projects')

    def prettyPrint(self):
        print self.doc.toprettyxml(encoding='utf-8')

if(__name__ == "__main__"):
    #getResources()
    lines = os.popen("ienv|grep 'irodsZone'").readlines()
    if(len(lines) == 1):
        zone = lines[0][len('NOTICE: irodsZone='):].strip()
        exporter = StatsExporter(zone)
        exporter.work()
        exporter.prettyPrint()
        exporter.close()
    #getProjectUsage()

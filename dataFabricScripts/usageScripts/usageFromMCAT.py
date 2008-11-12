#!/usr/bin/python
import pgdb, sys
import os
import xml.dom.minidom

class StatsExporter:
    def __init__(self, _zone):
        self.dbConn = pgdb.connect(dsn = 'localhost:MCAT:srb')
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
                if(listName == 'users'):
                    self.createChild(element, 'domain', row[2])
                resourceList = self.createChild(element, 'resources')
                lastUser = curUser
            resource = self.createChild(resourceList, 'resource')
            self.createChild(resource, 'id', row[3])
            self.createChild(resource, 'amount', row[4])
            self.createChild(resource, 'count', repr(row[5])[:-1])
            curUser = element

    def addRecordToDoc(self, query, listName):
        cur = self.doQuery(query)
        results = cur.fetchall()
        cur.close()
        self.processResults(listName, results)

    def work(self):
        query = """select userTable.user_name, userTable.zone_id,
                    domainTable.domain_desc, resourceTable.rsrc_name, 
                    sum(dataTable.data_size), count(dataTable.data_id)
                    from
                    mdas_cd_user as userTable,
                    mdas_ad_repl as dataTable,
                    mdas_td_data_grp as collTable,
                    mdas_td_domn as domainTable,
                    mdas_au_domn as inDomTable,
                    mdas_cd_rsrc as resourceTable
                    where
                    dataTable.data_owner = userTable.user_id and
                    inDomTable.user_id = userTable.user_id and
                    inDomTable.domain_id = domainTable.domain_id and
                    (collTable.data_grp_name like '/%s/home/%%' or
                    collTable.data_grp_name like '/%s/trash/%%' or
                    collTable.data_grp_name like '/%s/container/%%') and
                    dataTable.data_grp_id = collTable.data_grp_id and
                    resourceTable.rsrc_id = dataTable.rsrc_id 
                    group by userTable.user_name, userTable.zone_id, domainTable.domain_desc, resourceTable.rsrc_name
                    order by userTable.user_name, userTable.zone_id, domainTable.domain_desc, resourceTable.rsrc_name""" % (self.zone, self.zone, self.zone)
        self.addRecordToDoc(query, 'users')

        query = """select userTable.user_name, userTable.zone_id,
                    domainTable.domain_desc, resourceTable.rsrc_name, 
                    sum(dataTable.data_size), count(dataTable.data_id)
                    from
                    mdas_td_user_typ as groupTable,
                    mdas_cd_user as userTable,
                    mdas_au_domn as inDomTable,
                    mdas_td_domn as domainTable,
                    mdas_ad_repl as dataTable,
                    mdas_td_data_grp as collTable,
                    mdas_cd_rsrc as resourceTable
                    WHERE
                    groupTable.user_typ_name = 'group' and
                    inDomTable.user_id = userTable.user_id and
                    inDomTable.domain_id = domainTable.domain_id and
                    userTable.user_id = inDomTable.user_id and
                    userTable.user_typ_id = groupTable.user_typ_id and
                    collTable.coll_owner = userTable.user_id and
                    collTable.data_grp_name like '/%s/projects%%' and
                    dataTable.data_grp_id like (collTable.data_grp_id || '%%') and
                    dataTable.rsrc_id = resourceTable.rsrc_id
                    group by userTable.user_name, userTable.zone_id, domainTable.domain_desc, resourceTable.rsrc_name
                    order by userTable.user_name, userTable.zone_id, domainTable.domain_desc, resourceTable.rsrc_name""" % (self.zone)
        self.addRecordToDoc(query, 'projects')
    
    def prettyPrint(self):
        print self.doc.toprettyxml(encoding='utf-8')

if(__name__ == "__main__"):
    #getResources()
    lines = os.popen("Sinit -v|grep 'Client mcatZone'").readlines()
    if(len(lines) == 1):
        zone = lines[0][len('Client mcatZone = '):].strip()
        exporter = StatsExporter(zone)
        exporter.work()
        exporter.prettyPrint()
        exporter.close()
    #getProjectUsage()


#!/usr/bin/python
# Smv-U.py: Migrating users between two non-federated SRB servers by complete MCAT manipulation 

# The script requires the installation of postgresql-python.i386 package. Run:
# yum install postgresql-python.i386

import pgdb, string, sys, types

dbmod = pgdb

class table:
    
    _closed = True     

    def __init__(self, db, name):

            self.db = db
            self.name = name
            self.dbc = None
            self._new_cursor()
            self._search = ""
            self._sort = ""
            self._column = ""
            self._closed = False

    def sort(self, method):
		self._sort = ""
		if method: self._sort = "order by %s" % (method)

    def search(self, method):

            self._search = ""
	    if method: self._search = "where %s" % (method)
    
    def column(self, method):

            self._column = ""
            if method: self._column = "%s=" % (method)

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
 
    def update(self, item):

           q = "update %s set %s %s %s" % (self.name, self._column, item, self._search)
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

     def __init__(self, **args):
           self._tables = {}
           self._close = False
	   if args:
		 self.connect(**args)

     def table_reindex(self, name):

           c = self.obj.cursor()
           q = "reindex table %s" % name
	   e = c.execute(q)

     def connect(self, **args):
		self.obj = dbmod.connect(**args)

     def commit(self):
                self.obj.commit()

     def close(self):
           if not self._closed:
                try:
                   self.obj.close()
                except Exception:
                   pass
                   self._closed = true

def char_Processing(char):
   
    valChar = ord(char)
    if valChar in range(48, 57):
          if valChar == 57: char_b = 'a'
          else:
               char_b = chr(valChar + 1)
    elif valChar in range(97,122): 
          if valChar == 122: 
               char_b = '0'
          else: char_b = chr(valChar + 1)
    
    return char_b


def coll_ID_Processing(cList, seq_collID):
 
    mcList = []
    for i in range(len(cList)):
          coll_ID_len = len(seq_collID)
          last = seq_collID[coll_ID_len-1]
          last = char_Processing(last)
          if ord(last) == 48: 
                  last_1 = seq_collID[coll_ID_len-2]
                  last_1 = char_Processing(last)
                  seq_collID = seq_collID[0:2] + last_1 + last              
          else: seq_collID = seq_collID[0:3] + last
          mcList.append(seq_collID)

    return mcList

def domn_ID_Processing(seq):

    last =''
    seq_id = seq.split('.')
    
    for i in range(len(seq_id)):
        if seq_id[i] != '0001':
             seq_id_len = len(seq_id[i])
             last = seq_id[i][seq_id_len-1]
             valLast = ord(last)             
             if valLast in range(48, 57):
                   if valLast == 57: last = 'a'
                   else: 
                        last = chr(valLast + 1)
             elif valLast in range(97,122): last = chr(ord(valLast) + 1)
             seq_id[i] = seq_id[i][0:3] + last
    seq_id = '.'.join(seq_id)
    return seq_id

def main():

    dbMCAT = db(dsn = 'localhost:MCAT:srb')
    dbMCAT_ORI = db(dsn = 'localhost:MCAT_ORI:srb')    

    src1 = table(dbMCAT_ORI, 'mdas_td_zone')        
    src1.search("local_zone_flag=1")
    mdas_td_zone = src1["zone_id, user_id"]
    zone_ID_ORI = mdas_td_zone[0][0]
    srbAdmin_ID = mdas_td_zone[0][1]

    domain_ORI = 'srbrunner.hpcu.uq.edu.au'    

    src2 = table(dbMCAT_ORI, 'mdas_cd_user')
    src2.search("user_id>=100")            
    mdas_cd_user = src2["*"]
    for row in mdas_cd_user:
        if row[1] == domain_ORI: mdas_cd_user_domn_ID = row[0]
   
    src3 = table(dbMCAT_ORI, 'mdas_au_group')
    src3.search("user_id>=100")
    mdas_au_group = src3["*"]
    uidList = []
    for row in mdas_au_group:
        if row[0] !=row[1] and row[1] == mdas_cd_user_domn_ID: 
               uidList.append(row[0]) 
    uidList.append(mdas_cd_user_domn_ID)
    uidList.sort()
    del uidList[1]

    src4 = table(dbMCAT_ORI, 'mdas_au_mdata')
    mdas_au_mdata = src4["user_id, metadatanum"]

    src5 = table(dbMCAT_ORI, 'mdas_au_info')
    src5.search("user_id>=100")
    mdas_au_info = src5["*"]

    src6 = table(dbMCAT_ORI, 'mdas_au_auth_key')
    src6.search("user_id>=100")     
    mdas_au_auth_key = src6["*"]

    src7 = table(dbMCAT_ORI, 'mdas_au_auth_map')
    src7.search("user_id>=100") 
    mdas_au_auth_map = src7["*"]

    src8 = table(dbMCAT_ORI, 'mdas_au_domn')
    src8.search("user_id>=100")
    mdas_au_domn = src8["*"]

    src9 = table(dbMCAT_ORI, 'mdas_ad_guid')
    mdas_ad_guid = src9["*"]
    
    src10 = table(dbMCAT_ORI, 'mdas_ad_mdata')
    mdas_ad_mdata = src10["*"]

    src11 = table(dbMCAT_ORI, 'mdas_ad_accs')
    src11.search("data_id>=100")
    mdas_ad_accs = src11["*"] 

    src12 = table(dbMCAT_ORI, 'mdas_td_data_grp')                  
    mdas_td_data_grp = src12["*"]
    src12.search("data_grp_id like '0008.%'")
    ad_collmdata = src12["*"]

    find = 0
    ad_collmata_0008 = []
    collList = []
    for row in ad_collmdata:
        find = string.find(row[1], domain_ORI)
        if find > 0:
                   ad_collmata_0008.append(row)
                   collList.append(row[0].split('.')[1]) 

    src13 = table(dbMCAT_ORI, 'mdas_ad_grp_accs')
    mdas_ad_grp_accs = src13["*"]

    src14 = table(dbMCAT_ORI, 'mdas_ad_repl')
    mdas_ad_repl = src14["*"]

    src15 = table(dbMCAT_ORI, 'mdas_ad_collmdata')    
    mdas_ad_collmdata = src15["*"]

    src16 = table(dbMCAT_ORI, 'mdas_ar_physical')
    src16.search("phy_rsrc_id>=100")
    mdas_ar_physical = src16["phy_rsrc_id, phy_default_path"]
    rsrcDict ={}
    for row in  mdas_ar_physical:
        rsrcDict[row[0]] = row[1][:row[1].find("?USER")][1:]

    domain_DEST = 'quest.hpcu.uq.edu.au'
    resource_DEST = 'quest.hpcu.uq.edu.au'

    dest1 = table(dbMCAT, 'mdas_counter')
    dest1.search("cname='USER_ID'")
    userID = dest1['cvalue'][0][0]
    usrsDict = {}
    seq_usrID = userID
    for row in uidList:
       usrsDict[row] = seq_usrID
       seq_usrID += 1

    dest2 = table(dbMCAT, 'mdas_td_domn')
    dest2.search("domain_id like '0001.0001.0001.0001.000%'")
    mdas_td_domn = dest2[-1]
    mdas_td_domn_id = mdas_td_domn[0]
    domn_id = domn_ID_Processing(mdas_td_domn_id)
    domnRec = []
    domnRec.append(domn_id)
    domnRec.append(domain_ORI)
    print domnRec
    #dest2.insert(domnRec)

    dest3 = table(dbMCAT, 'mdas_td_zone')     
    dest3.search("local_zone_flag=1")
    mdas_td_zone = dest3["zone_id, user_id"]
    zone_ID_DEST = mdas_td_zone[0][0]         
    srbAdmin_ID_DEST = mdas_td_zone[0][1]

    dest4 = table(dbMCAT, 'dataid')
    dataID = dest4['last_value'][0][0]
    dataDict = {}
    _dataID = dataID
    for row in mdas_ad_guid:
        dataDict[row[0]] = _dataID
        _dataID += 1
 
    dest5 = table(dbMCAT, 'mdas_au_info')
    rec_au_info=[]
    for row in mdas_au_info:
           au_id = row[0]
           if usrsDict.has_key(au_id):
                  row[0] = usrsDict.get(au_id) 
                  rec_au_info.append(row)     
    for row in rec_au_info: 
           print row
           #dest5.insert(row)

    dest6 = table(dbMCAT, 'mdas_au_mdata')
    rec_au_mdata = []
    for row in  mdas_au_mdata:
             au_id = row[0]                 
             if usrsDict.has_key(au_id): 
                   row[0] = usrsDict.get(au_id)
                   rec_au_mdata.append(row)
    for row in rec_au_mdata:          
           print row
           #dest6.insert(row)

    dest7 = table(dbMCAT, 'mdas_au_auth_key')
    rec_au_auth_key = []
    for row in  mdas_au_auth_key:
             au_id = row[0] 
             if usrsDict.has_key(au_id):       
                   row[0] = usrsDict.get(au_id)
                   rec_au_auth_key.append(row)
    for row in rec_au_auth_key:
           print row
           #dest7.insert(row)

    dest8 = table(dbMCAT, 'mdas_au_group')
    rec_au_group = []
    for row in mdas_au_group:
           au_id = row[0] 
           grp_id = row[1]  
           if usrsDict.has_key(au_id):
                   row[0] = usrsDict.get(au_id)
                   if grp_id != 1 and usrsDict.has_key(grp_id):
                        row[1] = usrsDict.get(grp_id)
                   rec_au_group.append(row)
    for row in rec_au_group:          
           print row
           #dest8.insert(row)  

    dest9 = table(dbMCAT, 'mdas_cd_user')
    rec_cd_user = []
    for row in  mdas_cd_user:
            au_id = row[0]
            if usrsDict.has_key(au_id):
                   row[0] = usrsDict.get(au_id)
                   row[3] = zone_ID_DEST
                   rec_cd_user.append(row)     
    for row in rec_cd_user:
           print row
           #dest9.insert(row)
 
    dest10 = table(dbMCAT, 'mdas_au_domn')
    rec_au_domn = []
    for row in mdas_au_domn:
            au_id = row[0]
            if usrsDict.has_key(au_id):
                   row[0] = usrsDict.get(au_id)
                   if row[0] == mdas_cd_user_domn_ID: row[1] = domn_id
                   rec_au_domn.append(row)
    for row in rec_au_domn:
           print row
           #dest10.insert(row)

    dest11 = table(dbMCAT, 'mdas_au_auth_map')
    rec_au_auth_map = []
    for row in mdas_au_auth_map:
            au_id = row[0]                 
            if usrsDict.has_key(au_id):
                   row[0] = usrsDict.get(au_id)
                   rec_au_auth_map.append(row)
    for row in rec_au_auth_map:
           print row
           #dest11.insert(row) 

    dest12 = table(dbMCAT, 'mdas_ad_guid')
    rec_ad_guid = []
    for row in mdas_ad_guid:
            row[0] = dataDict.get(row[0])
            seg = row[1].split(':')
            row[1] = seg[0] + ':'+ str(row[0])
            rec_ad_guid.append(row)
    for row in rec_ad_guid:
            print row                      
            #dest12.insert(row)   

    dest13 = table(dbMCAT, 'mdas_ad_mdata')   
    rec_ad_mdata = [] 
    for row in mdas_ad_mdata:   
            row[0] = dataDict.get(row[0])
            rec_ad_mdata.append(row)
    for row in rec_ad_mdata:
            print row                        
            #dest13.insert(row)   
  
    dest14 = table(dbMCAT, 'mdas_ad_accs')
    rec_ad_accs = []
    for row in mdas_ad_accs:
            row[0] = dataDict.get(row[0])
            row[2] = usrsDict.get(row[2])
            rec_ad_accs.append(row)
    for row in rec_ad_accs:
            print row
            #dest14.insert(row)
    
    dest15 = table(dbMCAT, 'mdas_ad_collmdata')        
    dest15.search("data_grp_id like '0008.%'")
    mdas_ad_collmdata_d = dest15[-1]
    d_collID = mdas_ad_collmdata_d[0].split('.')[1]
     
    collDict = {}
    collValue = coll_ID_Processing(collList, d_collID)
    for i in range(len(collList)):
        collDict[collList[i]] = collValue[i]

    rec_collmdata = []
    for row in mdas_ad_collmdata:
        coll = row[0].split('.')
        if len(coll) > 1 and collDict.has_key(coll[1]):  
                coll[1] = collDict.get(coll[1])    
                row[0] = '.'.join(coll)
                rec_collmdata.append(row)              
    for row in rec_collmdata:
          print row
          #dest15.insert(row)

    dest16 = table(dbMCAT, 'mdas_ad_grp_accs')
    rec_ad_grp_accs = []
    for row in mdas_ad_grp_accs:
         coll = row[0].split('.')
         c_uid = row[1]    
         if len(coll) > 1 and collDict.has_key(coll[1]):
                coll[1] = collDict.get(coll[1])
                row[0] = '.'.join(coll)
                if row[1] ==  srbAdmin_ID: row[1] = srbAdmin_ID_DEST 
                elif row[1] != 2: row[1] = usrsDict.get(c_uid)
                if row[1] != None: rec_ad_grp_accs.append(row)  
    for row in rec_ad_grp_accs:
          print row
          #dest16.insert(row)           
   
    dest17 = table(dbMCAT, 'mdas_ar_physical')
    mdas_ar_physical = dest17["phy_rsrc_name, phy_default_path"]
    for row in mdas_ar_physical:
        if row[0] == resource_DEST: default_path = row[1] 
    loc = default_path.find("?USER")
    path_name = default_path[:loc]

    dest18 = table(dbMCAT, 'mdas_td_data_grp')
    rec_td_data_grp = []
    for row in mdas_td_data_grp:
         coll = row[0].split('.')
         c_oid = row[3]
         if len(coll) > 1 and collDict.has_key(coll[1]):
                coll[1] = collDict.get(coll[1])
                row[0] = '.'.join(coll)
                if c_oid == srbAdmin_ID: row[3] = srbAdmin_ID_DEST
                else: row[3] = usrsDict.get(c_oid)
                data = row[1]
                find = string.find(data, domain_ORI)
                if find > 0: 
                     row[1] = data.replace(r'/'+domain_ORI,'/'+domain_DEST,1)
                     find = 0
                data_p = row[2]
                find = string.find(data_p, domain_ORI)
                if find > 0:
                     row[2] = data_p.replace(r'/'+domain_ORI,'/'+domain_DEST,1)
                     find = 0    
                if row[3] !=None: rec_td_data_grp.append(row)
    for row in rec_td_data_grp:
        if row[0] == '0006.000b': row[1] = '/home/' + domain_ORI + '.groups'
        if row[0] == '0008.000b': row[1] = '/container/' + domain_ORI + '.groups'
    for row in rec_td_data_grp:
          print row
          #dest18.insert(row)

    dest19 = table(dbMCAT, 'mdas_ad_repl') 
    rec_ad_repl = []
    for row in mdas_ad_repl:
         d_id = row[0]
         coll = row[7].split('.')
         c_oid = row[10]
         if len(coll) > 1 and collDict.has_key(coll[1]):
                coll[1] = collDict.get(coll[1])
                row[7] = '.'.join(coll)
                row[10] = usrsDict.get(c_oid)
                row[0] = dataDict.get(d_id)
                row[13] = dataDict.get(d_id)
                path_prefix = rsrcDict.get(row[5])
                row[4] =row[4].replace(r'/'+path_prefix, path_name)
                if row[10] != None: rec_ad_repl.append(row)
    for row in rec_ad_repl:
          print row[0], row[2], row[4], row[7], row[10], row[13]
          #dest19.insert(row)

    dbMCAT.table_reindex("mdas_cd_user")
    dbMCAT.table_reindex("mdas_td_domn")
    dbMCAT.table_reindex("mdas_au_domn")
    dbMCAT.table_reindex("mdas_ad_repl")
    dbMCAT.table_reindex("mdas_td_data_grp")

    dbMCAT.commit()    
    dbMCAT.close()
    dbMCAT_ORI.close()
 
if __name__=="__main__":
    sys.exit(main())




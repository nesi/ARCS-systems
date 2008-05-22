#!/usr/bin/python
# userSync.py: Syncronize users between GUMS and SRB

import MySQLdb, pg, ConfigParser, sys, numpy, random, os

# make sure configration file attribute was given
try:
    sys.argv[1]
except IndexError:
    print "Usage: userSync.py <CONFIGFILE>"
    sys.exit(0)

# read the configuration file
configParser = ConfigParser.SafeConfigParser()
try:
    configParser.readfp(open(sys.argv[1]))
except IOError:
    print "Configuration File %s not found."%(sys.argv[1])

# briefly check config file sanity
if not configParser.has_section('MCAT') or not configParser.has_section('GUMS') or not configParser.has_section('SRB'):
    print "Config file is not correct."
    sys.exit(0)

# connect to and get info from  MCAT database
try:
    dbMCAT = pg.connect(dbname=configParser.get('MCAT','dbName'),host=configParser.get('MCAT','dbHost'))
except:
    print "Error connection to MCAT database. Check settings."
    sys.exit(0)

userInfoMCAT = dbMCAT.query('SELECT user_name,zone_id,distin_name from mdas_cd_user LEFT JOIN mdas_au_auth_map on mdas_cd_user.user_id=mdas_au_auth_map.user_id;').getresult()
dbMCAT.close()

# connect to and get info from GUMS database
try:
    dbGUMS = MySQLdb.connect(host=configParser.get('GUMS','dbHost'),user=configParser.get('GUMS','dbUser'),passwd=configParser.get('GUMS','dbPassword'),db=configParser.get('GUMS','dbName'),port=int(configParser.get('GUMS','dbPort')))
except:
    print "Error connecting so GUMS database. Check settings."
    sys.exit(0)

dbGUMSCursor = dbGUMS.cursor()
dbGUMSCursor.execute('SELECT * from MAPPING;')
userInfoGUMS = dbGUMSCursor.fetchall()
dbGUMS.close()

# get rid of tuples
userInfoMCAT = numpy.array(userInfoMCAT)
userInfoGUMS = numpy.array(userInfoGUMS)

for i in userInfoGUMS[:][:,3]:
    dn = userInfoGUMS[numpy.where(userInfoGUMS[:][:,3] == i)][0][2]
    if i in userInfoMCAT[:][:,0]:
        #a = userInfoMCAT[numpy.where(userInfoMCAT[:][:,0] == i)]
        if len(numpy.where(userInfoMCAT[numpy.where(userInfoMCAT[:][:,0] == i)][numpy.where(userInfoMCAT[numpy.where(userInfoMCAT[:][:,0] == i)][:][:,1] == 'srb.ivec.org')][:][:,2] != 'NULL')) == 0:
            os.system('Sinit && SmodifyUser addDN %s %s %s && Sexit'%(i, configParser.get('SRB','srbDomain'), dn))
    if i not in userInfoMCAT[:][:,0]:
        command = 'Sinit && Singestuser %s %s %s staff "" "" "" GSI_AUTH "%s" && Sexit'%(i, str(random.randrange(0,1000000000)), configParser.get('SRB','srbDomain'), dn)
        print 'runing: ' + command
        os.system(command)

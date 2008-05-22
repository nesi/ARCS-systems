#!/usr/bin/python
# userSync.py: Syncronize users between GUMS and SRB

import pg, ConfigParser, sys, numpy, random, os

# make sure configration file attribute was given
try:
    sys.argv[1]
except IndexError:
    print "Usage: userGridMap.py <CONFIGFILE>"
    sys.exit(0)

# read the configuration file
configParser = ConfigParser.SafeConfigParser()
try:
    configParser.readfp(open(sys.argv[1]))
except IOError:
    print "Configuration File %s not found."%(sys.argv[1])

# briefly check config file sanity
if not configParser.has_section('MCAT') or not configParser.has_section('MAPFILE') or not configParser.has_section('SRB'):
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

try:
    mapfile = open(configParser.get('MAPFILE','map'),'r')
except:
    print "Can't open grid-mapfile: %s for reading. Leaving."%(configParser.get('MAPFILE','map'))
    sys.exit(0)

mapfileLines = mapfile.readlines()
mapfile. close()
mappedUsers = []
for line in mapfileLines:
    mappedUsers.append(line.strip().split(' ')[-1])

# get rid of tuples
mappedUsers = numpy.array(mappedUsers)
userInfoMCAT = numpy.array(userInfoMCAT)

try:
    mapfile = open(configParser.get('MAPFILE','map'),'a')
except:
    print "Can't open grid-mapfile: %s for appending. Leaving."%(configParser.get('MAPFILE','map'))
    sys.exit(0)

for i in userInfoMCAT[numpy.where(userInfoMCAT[:][:,2] != 'NULL')]:
    map = i[0] + '@' + i[1]
    if map not in mappedUsers:
        mapfile.write('"%s" %s\n'%(i[2],map))

mapfile.close()

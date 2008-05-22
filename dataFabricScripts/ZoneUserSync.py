import os, sys, numpy, random

administrativeZones = ['srb-dev.ivec.org']
ignoreDomains = ['sdsc','npaci']

def makeUsersArray (filehandle):
	try:
		f = open(filehandle, 'r')
	except:
		sys.stderr.write('Failed to open %s.'%(filehandle))
		sys.exit(-1)
	lines = f.readlines()
	array = []
	for line in lines[2:]:
		tmp = line.strip().split('|')
		tmp.pop(-1)
		tmp.pop(-1)
		tmp.pop(1)
		tmp.pop(3)
		tmp.pop(3)
		array.append(tmp)
	return array

def getcurrentDomains ():
	try:
		lines = os.popen('/usr/bin/Stoken Domain').readlines()
	except:
		sys.stderr.write('Error getting domains.')
		sys.exit(-1)
	domains = []
	for line in lines:
    		if line[0] == '-':
        		pass
    		else:
        		domains.append(line.strip().split(': ')[-1])
	return domains
	

def createDomain (domain):
	res = os.system('/usr/bin/Singesttoken Domain %s home'%(domain))
	return res

def modUser (u,currentDomains,currentZones):
	if u['Domain'] in ignoreDomains:
		return 0
	if u['Type'] == 'group':
		return 0
	if u['Domain'] not in currentDomains:
		res = createDomain(u['Domain'])
		if res != 0:
			sys.stderr.write('Error creating Domain %s.'%(u['Domain']))
			sys.exit(-1)
	res = os.system('SmodifyUser changeType %s %s %s'%(u['Name'], u['Domain'], u['Type']))
	print('SmodifyUser changeType %s %s %s'%(u['Name'], u['Domain'], u['Type']))
	return res


def createUser (u,currentDomains,currentZones):
	if u['Zone'] not in currentZones:
		return 0
	if u['Domain'] in ignoreDomains:
		return 0
	if u['Domain'] not in currentDomains:
		res = createDomain(u['Domain'])
		if res != 0:
			sys.stderr.write('Error creating Domain %s.'%(u['Domain']))
			sys.exit(-1)
	if u['Type'] == 'group':
		return 0
	else:
		print("Singestuser %s %s %s %s '' '' '' ENCRPYT1 '' %s"%(u['Name'], random.randrange(1,1000000000), u['Domain'], u['Type'], u['Zone']))
		res = os.system("Singestuser %s %s %s %s '' '' '' ENCRPYT1 '' %s"%(u['Name'], random.randrange(1,1000000000), u['Domain'], u['Type'], u['Zone']))
		return res
	
try:
	currentUsersFile = sys.argv[1]
except:
	print 'Usage: %s <CURRENT_USERS_FILE> <NEW_USERS_FILE> <CURRENT SYNCING ZONE>'%(sys.argv[0])
try:
	newUsersFile = sys.argv[2]
except:
	print 'Usage: %s <CURRENT_USERS_FILE> <NEW_USERS_FILE> <CURRENT SYNCING ZONE>'%(sys.argv[0])
try:
	currentSyncZone = sys.argv[3]
except:
	print 'Usage: %s <CURRENT_USERS_FILE> <NEW_USERS_FILE> <CURRENT SYNCING ZONE>'%(sys.argv[0])

currentUsersArray = makeUsersArray(currentUsersFile)
newUsersArray = makeUsersArray(newUsersFile)


tmpCurrentArray = numpy.array(currentUsersArray)
currentDomains = getcurrentDomains()
currentZones = numpy.unique(tmpCurrentArray[:,3])

for user in newUsersArray:
	if user not in currentUsersArray:
		u = {}
		u['Name'] = user[1]
		u['Domain'] = user[2]
		u['Type'] = user[0]
		u['Zone'] = user[3]
		#u['ModTime'] = user[8]
		#u['Address'] = user[1]
		currentUsersArrayIndex = numpy.where(tmpCurrentArray[:,1] == u['Name'])[0]
		if len(currentUsersArrayIndex) > 0 and u['Zone'] == currentSyncZone:
			index = 0
			for count in range(len(currentUsersArrayIndex)):
				index += 1
				domain = tmpCurrentArray[:,3][currentUsersArrayIndex[count]]
				if domain == u['Domain']:
					if u['Zone'] not in administrativeZones:
						modUser(u, currentDomains, currentZones)
						break
					if index == len(currentUsersArrayIndex):
						if u['Zone'] not in administrativeZones:
							createUser(u, currentDomains, currentZones)
		elif u['Zone'] == currentSyncZone:
			if u['Zone'] not in administrativeZones:
				createUser(u, currentDomains, currentZones)
		else:
			pass

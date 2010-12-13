#! /usr/bin/env python
#	replicate:	Version 1.0
#				External repliation logic for iRODS to be called from rules like
#				acPostProcForPut||delayExec(<PLUSET>30s</PLUSET>,msiExecCmd(replicate,$dataId,null,null,null,*REPLI_OUT)),nop)|nop


import sys
import re
import os
import psycopg2
import time
import logging
import logging.handlers
import subprocess

#logging setup
logFileName = '/opt/iRODS/iRODS/server/log/AutoReplicator.log'
debugLogger = logging.getLogger('debugLogger')
debugLogger.setLevel(logging.DEBUG)
handler = logging.handlers.RotatingFileHandler(logFileName, maxBytes=52428800, backupCount=10)
debugLogger.addHandler(handler)

def getDBSettings(filename):
	f = open(filename, 'r')
	settings = {}
	for line in f:
		try:
			configItem = line.strip().split(' = ')[0]
			if configItem == "$DATABASE_ADMIN_PASSWORD":
				settings["DATABASE_ADMIN_PASSWORD"] = line.strip().split(' = ')[1].strip(";").strip("'")
			if configItem == "$DB_NAME":
				settings["DB_NAME"] = line.strip().split(' = ')[1].strip(";").strip("'")
			if configItem == "$DATABASE_HOST":
				settings["DATABASE_HOST"] = line.strip().split(' = ')[1].strip(";").strip("'")
			if configItem == "$DATABASE_ADMIN_NAME":
					settings["DATABASE_ADMIN_NAME"] = line.strip().split(' = ')[1].strip(";").strip("'")
		except Exception, e:
			pass
	if len(settings) == 4:
		return settings
	else:
		debugLogger.debug(time.ctime() + 'Configuration file invalid. File: ' + filename)
		return -1

#DB Connection Settings
iRodsConfigFile = '/opt/iRODS/iRODS/config/irods.config'
dbSettings = getDBSettings(iRodsConfigFile)

#Replication Settings
replicationCommand = '/opt/iRODS/iRODS/clients/icommands/bin/irepl'
trimCommand = '/opt/iRODS/iRODS/clients/icommands/bin/itrim'
targetResource = 'ARCS-REPLISET'
timeDelayInSec = 15
lockDir = '/opt/iRODS/iRODS/server/bin/cmd/repliLock'
if not os.path.exists(lockDir):
	try:
		os.mkdirs(lockDir)
	except Exception, e:
		raise e


def queryICAT(statement):
	connectionString = "dbname=" + dbSettings["DB_NAME"] + " user=" + dbSettings["DATABASE_ADMIN_NAME"] + " host=" + dbSettings["DATABASE_HOST"] + " password=" + dbSettings["DATABASE_ADMIN_PASSWORD"]
	try:
		conn = psycopg2.connect(connectionString)
		cur = conn.cursor()
	except Exception, e:
		raise e
	try:
		cur.execute(statement)
		results = cur.fetchall()
		conn.close()
	except Exception, e:
		raise e
	return results
	
def getRecordsForDataID(dataID):
	query = """select d.data_id, c.coll_name || '/' || d.data_name as path, d.resc_name, \
	d.modify_ts from r_data_main d join r_coll_main c using (coll_id )where d.data_id = """ + str(dataID)
	results = queryICAT(query)
	return results

def checkTime(dataRecords):
	mostCurrentModifyTime = 0
	for record in dataRecords:
		if int(record[3]) > mostCurrentModifyTime:
			mostCurrentModifyTime = int(record[3])
	if int(time.time()) - mostCurrentModifyTime > timeDelayInSec:
		return 0
	else:
		debugLogger.debug(time.ctime() + ': File to current. Assumed upload through iSFTPD for file: ' + dataRecords[0][1] + '. DiffTime: ' + str(int(time.time()) - mostCurrentModifyTime))
		return -1
		
def executeSystemCommand(command):
	try:
	    retcode = subprocess.call(command, shell=True)
	    if retcode != 0:
	        return -1
	    else:
	        return 0
	except OSError, e:
	    return -1

def lock(dataID):
	lockFile = lockDir + '/' + str(dataID)
	if os.path.exists(lockFile):
		debugLogger.debug(time.ctime() + ': lockFile exists for dataID: ' + str(dataID))
		return -1
	else:
		try:
			open(lockFile, 'w').close()
			debugLogger.debug(time.ctime() + ': locked for dataID: ' + str(dataID))
			return 0
		except Exception, e:
			return -1

def unlock(dataID):
	lockFile = lockDir + '/' + str(dataID)
	if not os.path.exists(lockFile):
		debugLogger.debug(time.ctime() + ": lockFile doesn't exist for dataID: " + str(dataID))
		return -1
	else:
		try:
			os.remove(lockFile)
			debugLogger.debug(time.ctime() + ": unlocked for dataID: " + str(dataID))
			return 0
		except Exception, e:
			return -1
	
def replicate(dataID):
	if lock(dataID) == -1:
		return -1
	dataRecords = getRecordsForDataID(dataID)
	if checkTime(dataRecords) == -1:
		unlock(dataID)
		return -1
	iRodsPath = re.escape(dataRecords[0][1])
	if len(dataRecords) == 1:
		debugLogger.debug(time.ctime() + ': Starting fresh replication on file: ' + dataRecords[0][1] + ' ...')
		if executeSystemCommand(replicationCommand + ' -M -B -R ' + targetResource + ' ' + iRodsPath) == 0:
			executeSystemCommand(trimCommand + ' -M ' + iRodsPath)
			debugLogger.debug(time.ctime() + ': Replication done for: ' + dataRecords[0][1])
			unlock(dataID)
			return 0
		else:
			debugLogger.debug(time.ctime() + ': Replication failed for: ' + dataRecords[0][1])
			unlock(dataID)
			return -1
	else:
		debugLogger.debug(time.ctime() + ': Starting update replication on file: ' + dataRecords[0][1] + ' ...')
		if executeSystemCommand(replicationCommand + ' -M -U -R ' + targetResource + ' ' + iRodsPath) == 0:
			executeSystemCommand(trimCommand + ' -M ' + iRodsPath)
			debugLogger.debug(time.ctime() + ': Replication done for: ' + dataRecords[0][1])
			unlock(dataID)
			return 0
		else:
			debugLogger.debug(time.ctime() + ': Replication failed for: ' + dataRecords[0][1])
			unlock(dataID)
			return -1

def main(args):
	if len(args) < 2:
		print 'Usage: <python> <scriptname> DATA_ID'
		return -1
	try:
		dataID = int(args[1])
	except:
		print 'First Argument must be an integer.'
		return -1
	if replicate(dataID) == 0:
		return 0
	else:
		debugLogger.debug(time.ctime() + ': replicate returned -1 but sending 0 to keep rules engine happy. DataID: ' + str(dataID))
		return 0

if __name__ == '__main__':
	main(sys.argv)

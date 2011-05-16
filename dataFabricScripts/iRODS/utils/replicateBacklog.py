#! /usr/bin/env python

import sys
import re
import os
import psycopg2
import time
import logging
import logging.handlers
import subprocess

def getPassword(filename):
	f = open(filename, 'r')
	match = 1
	password = -1
	for line in f:
		try:
			configItem = line.strip().split(' = ')[0]
			if configItem == "$DATABASE_ADMIN_PASSWORD":
				password = line.strip().split(' = ')[1].strip(";").strip("'")
		except Exception, e:
			pass
	return password

#logging setup
logFileName = '/opt/iRODS/iRODS/server/log/BacklogReplicator.log'
debugLogger = logging.getLogger('debugLogger')
debugLogger.setLevel(logging.DEBUG)
handler = logging.handlers.RotatingFileHandler(logFileName, maxBytes=52428800, backupCount=10)
debugLogger.addHandler(handler)

#DB Connection Settings
iRodsConfigFile = '/opt/iRODS/iRODS/config/irods.config'
dbHost = 'arcs-db.vpac.org'
dbName = 'ICAT'
dbUser = 'rods'
dbPass = getPassword(iRodsConfigFile)

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
	connectionString = "dbname=" + dbName + " user=" + dbUser + " host=" + dbHost + " password=" + dbPass
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

def checkTime(dataRecord):
	if int(time.time()) - int(dataRecord[3]) > timeDelayInSec:
		return 0
	else:
		debugLogger.debug(time.ctime() + ': File currently being changed: ' + dataRecords[0][1] + '. DiffTime: ' + str(int(time.time()) - mostCurrentModifyTime))
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

def executeSystemCommand(command):
	print command
	try:
	    retcode = subprocess.call(command, shell=True)
	    if retcode != 0:
	        return -1
	    else:
	        return 0
	except OSError, e:
	    return -1

def replicate(query):
	records = queryICAT(query)
	numRecords = len(records)
	numRecordsLeft = numRecords
	print 'Total Number of Files to replicate: ' + str(numRecords) + "\n"
	for record in records:
		numRecordsLeft = numRecordsLeft - 1
		iRodsPath = re.escape(record[0])
		if checkTime(record) == 0 and lock(record[3]) == 0:
			debugLogger.debug(time.ctime() + ': Starting replication on file: ' + iRodsPath + ' ...')
			if executeSystemCommand(replicationCommand + ' -M -B -R ' + targetResource + ' ' + iRodsPath) == 0:
				debugLogger.debug(time.ctime() + ': Replication done for: ' + iRodsPath)
			else:
				debugLogger.debug(time.ctime() + ': Replication failed for: ' + iRodsPath)
			unlock(record[3])
			print str(numRecordsLeft) + " records to go."
			
	return 0
	
def trim(query):
	records = queryICAT(query)
	numRecords = len(records)
	numRecordsLeft = numRecords
	print 'Total Number of Files to trim: ' + str(numRecords) + "\n"
	for record in records:
		numRecordsLeft = numRecordsLeft - 1
		iRodsPath = re.escape(record[0])
		if checkTime(record) == 0 and lock(record[3]) == 0:
			debugLogger.debug(time.ctime() + ': Starting trim on file: ' + iRodsPath + ' ...')
			if executeSystemCommand(replicationCommand + ' -M -U -R ' + targetResource + ' ' + iRodsPath) == 0:
				executeSystemCommand(trimCommand + ' -M ' + iRodsPath)
				debugLogger.debug(time.ctime() + ': Trim done for: ' + iRodsPath)
			else:
				debugLogger.debug(time.ctime() + ': Trim failed for: ' + iRodsPath)
			unlock(record[3])
			print str(numRecordsLeft) + " records to go."
			
	return 0

def main():
	#query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where resc_name not like '%emii%' and data_is_dirty = 1 and coll_name not like '%Archive_S3%' and coll_name not like '%MiraJobs%' and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) = 1)"""
	query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where resc_name not like '%emii%' and data_is_dirty = 1 and data_size > 0 and coll_name not like '%Archive_S3%' and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) = 1)"""
	#query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 1 and coll_name not like '%Archive_S3%' and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) = 1)"""
	#query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 1 and coll_name not like '%Archive_S3%' and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and coll_name not like '%IMOS/staging%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) = 1)"""
	#query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 1 and coll_name not like '%Archive_S3%' and coll_name not like '/ARCS/trash%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) = 1)"""
	replicate(query)
	
	query = """select c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 0 and data_size > 0 and coll_name not like '%Archive_S3%' and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and coll_name not like '%IMOS/staging%' and data_id in (select d.data_id from r_data_main d where d.data_size > 0 group by data_id having count(d.data_id) < 3)"""
	replicate(query)
	
	#query = """select distinct on (data_id) c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 0 and data_size > 0 and coll_name not like '/ARCS/trash%' and coll_name not like '%ANSTO%' and coll_name not like '%projects/EMXRAY%' and coll_name not like '%IMOS/staging%' and coll_name not like '%Archive_S3%'"""
	query = """select distinct on (data_id) c.coll_name || '/' || d.data_name as path, resc_name, d.modify_ts, d.data_id from r_data_main d JOIN r_coll_main c USING (coll_id) where data_is_dirty = 0 and data_size > 0 and coll_name not like '/ARCS/trash%' and coll_name not like '%Archive_S3%'"""
	trim(query)
	
	return 0
	
if __name__ == '__main__':
	main()
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

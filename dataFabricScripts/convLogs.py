#!/usr/bin/python
# convLogs.py: Converting logs from Table mdas_audit to file

# The script requires the installation of postgresql-python.i386 package. Run:
# yum install postgresql-python.i386

import pgdb, sys, os

try:
    logFile = open('/usr/srb/data/log/srbAudit','a')
except:
    print "Can't open log file: srbAudit for appending"
    sys.exit(0)

try:
     dbMCAT = pgdb.connect('localhost:MCAT:srb')
except:
    print "Error connection to MCAT database. Please check settings."
    sys.exit(0)

curs = dbMCAT.cursor()
curs.execute ('select a.aud_timestamp, b.actiondesc, c.user_name, a.dataid, a.aud_comments from ((mdas_audit as a left outer join mdas_audit_desc as b on (a.actionid=b.actionid)) left outer join mdas_cd_user as c on (a.userid=c.user_id))')
auditInfoMCAT = curs.fetchall ()
for i in auditInfoMCAT:
    logs = i[0] + '::' + i[1]+ '::' + i[2]+'::' + str(i[3])+'::' + i[4]
    logFile.write('%s\n'%logs)
    curs.execute("delete from mdas_audit where aud_timestamp='%s' and aud_comments='%s'" % (i[0], i[4]))
curs.close()
dbMCAT.commit()
dbMCAT.close()
logFile.close()

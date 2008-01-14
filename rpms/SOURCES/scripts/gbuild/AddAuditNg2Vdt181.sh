#!/bin/sh
# AddAuditNg2Vdt181.sh APAC NG2 gateway Audit database installation.
#		       Gerson Galang <gerson.galang@sapac.edu.au> and
#		       Graham Jenkins <graham@vpac.org> Dec 2006, Rev 20070216
#		       Youzhen Cheng <Youzhen.Cheng@ac3.edu.au>, Rev 20080114

#
# id-check, etc.
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
grep AUDIT $GLOBUS_LOCATION/container-log4j.properties >/dev/null &&
                               echo "==> Audit Database already installed!" && exit 2
mysql </dev/null 2>&1|grep ERROR >/dev/null &&
                echo "==> You must start mysql before running this progam!" && exit 2

#
# Create the Audit database and the Gram_Audit table
Pass="Audi"`perl -e 'print int(99999999*rand())'`
Host=`host -t A $HOSTNAME | awk '{print $1}'`
IpAd=`host -t A $HOSTNAME | awk '{print $NF}'`
#mysql <<EOF
#create database auditDatabase;
#grant  USAGE ON *.* TO 'audit'@'localhost' IDENTIFIED BY '$Pass';
#grant  ALL PRIVILEGES ON auditDatabase.* TO 'audit'@'localhost';
#grant  USAGE ON *.* TO 'audit'@'$Host' IDENTIFIED BY '$Pass';
#grant  ALL PRIVILEGES ON auditDatabase.* TO 'audit'@'$Host';
#EOF

# 2008-01-14, Youzhen, fixed multiple interface entry problem
(
cat <<EOF
create database auditDatabase;
EOF

for each in localhost 127.0.0.1 $Host $IpAd
do
cat <<EOF
grant  USAGE ON *.* TO 'audit'@'$each' IDENTIFIED BY '$Pass';
grant  ALL PRIVILEGES ON auditDatabase.* TO 'audit'@'$each';
EOF
done
) | mysql


mysql auditDatabase < $GLOBUS_LOCATION/share/gram-service/gram_audit_schema_mysql.sql

#
# Modify jndi-config.xml
sed --in-place=.ORI -e 's%org.postgresql.Driver%com.mysql.jdbc.Driver%' \
                    -e 's%jdbc:postgresql%jdbc:mysql%'                  \
                    -e 's%/auditDatabase%:49151/auditDatabase%'         \
                    -e 's%root%audit%'                                  \
                    -e 's%auditdbpassword%'$Pass'%'                               \
                       $GLOBUS_LOCATION/etc/gram-service/jndi-config.xml
#
# Activate Audit!
cat >>$GLOBUS_LOCATION/container-log4j.properties <<EOF
# GRAM AUDIT
log4j.appender.AUDIT=org.globus.exec.utils.audit.AuditDatabaseAppender
log4j.appender.AUDIT.layout=org.apache.log4j.PatternLayout
log4j.category.org.globus.exec.service.exec.StateMachine.audit=DEBUG, AUDIT
log4j.additivity.org.globus.exec.service.exec.StateMachine.audit=false
EOF
echo "Audit has been activated. When ready, do:"
echo "  service globus-ws stop; service globus-ws start"
exit 0

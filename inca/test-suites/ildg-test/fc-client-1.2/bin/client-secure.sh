#!/bin/sh

#export LROOT=/afs/ifh.de/group/ape/ldg/lroot
#source $LROOT/etc/env.sh

CLASSPATH=.:"`echo /home/shundezh/fc-client/lib/*.jar | sed 's/ /:/g'`"

export JAVA_HOME="/opt/jdk1.5.0_07"


#-DX509_USER_PROXY="${X509_USER_PROXY}" \
	
#### content of dlgor.properties #####
#issuerCertFile=/afs/ifh.de/user/m/mdavid/k5-ca-proxy.pem
#issuerKeyFile=/afs/ifh.de/user/m/mdavid/k5-ca-proxy.pem
#issuerPass=something

${JAVA_HOME}/bin/java \
	-Dlog4j.configuration="file:../conf/log4j.properties" \
	-DGLITE_DLGOR_PROPERTY="/home/shundezh/fc-client/conf/dlgor.properties" \
	-DX509_USER_PROXY="${X509_USER_PROXY}" \
	-DgridProxyFile="${X509_USER_PROXY}" \
	-DsslCAFiles="${X509_CERT_DIR}" \
	-classpath ${CLASSPATH}	"org.lqcd.ildg.fc.client.Client" $*
#\
#	-lhttps://globe-meta.ifh.de:6443/axis/services/ILDG_FC \
#	-dhttps://globe-meta.ifh.de:6443/axis/services/Delegation -ogetURL $*

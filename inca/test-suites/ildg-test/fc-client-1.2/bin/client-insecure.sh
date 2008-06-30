#!/bin/sh

CLASSPATH="`echo ../lib/*.jar | sed 's/ /:/g'`"

JAVA_HOME="/afs/ifh.de/@sys/products/java/1.5.0"

PATH=${JAVA_HOME}/bin:$PATH

export JAVA_HOME PATH

${JAVA_HOME}/bin/java -Dlog4j.configuration="file:../conf/log4j.properties" \
	-cp ${CLASSPATH} \
	org.lqcd.ildg.fc.client.Client \
	-lhttp://globe-meta.ifh.de:8080/axis/services/ILDG_FC \
	-ogetURL $*

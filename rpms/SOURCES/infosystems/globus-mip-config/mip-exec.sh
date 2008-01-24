#!/bin/sh

MIP="/usr/local/mip/mip"
SCHEMA="/usr/local/share/APACGLUESchema12R1.xsd"
VERIFY="xmllint --schema $SCHEMA -"

if [ "$1" != "-validate" ]; then
	VERIFY="$VERIFY 2>/dev/null"
fi

$MIP glue | sed \
	-e '/Site UniqueID=/ s|>| xmlns="http://forge.cnaf.infn.it/glueschema/Spec/V12/R2" xmlns:apac="http://grid.apac.edu.au/glueschema/Spec/V12/R1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">|' \
	-e '/SubCluster UniqueID=/ s/>/ xsi:type="apac:APACSubClusterType" >/' \
	-e '/SoftwarePackage LocalID=/ s|>| xmlns="http://grid.apac.edu.au/glueschema/Spec/V12/R1" >|' | eval "$VERIFY"


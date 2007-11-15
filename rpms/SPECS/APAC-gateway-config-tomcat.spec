%define PREFIX /usr/local
%define DEP apache-tomcat

Summary: Tomcat configuration for APAC gateways, environment and startup script
Name: APAC-gateway-config-tomcat
Version: 0.1
Release: 2
License: Apache
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
Requires: APAC-apache-tomcat-jsvc, APAC-gateway-config-java
BuildArch: noarch

%description
Adds CATALINA_HOME environment variable for APAC gateways and provides an init script for tomcat

%install
mkdir -p $RPM_BUILD_ROOT/etc/profile.d

cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/tomcat.sh
export CATALINA_HOME="%{PREFIX}/%{DEP}"
EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/tomcat.csh
setenv CATALINA_HOME "%{PREFIX}/%{DEP}"
EOF

#mkdir -p $RPM_BUILD_ROOT%{PREFIX}
#ln -s %{PREFIX}/%{DEP}-`rpm -qi APAC-%{DEP} | awk '/^Version/ {print $3}'` $RPM_BUILD_ROOT%{PREFIX}/%{DEP}


mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d 
cat <<EOF > $RPM_BUILD_ROOT/etc/rc.d/init.d/tomcat
#!/bin/sh
#
# tomcat.sh                      The Apache Tomcat 5.5 Servlet/JSP Container
# modified by Andrew Sharpe - Fri Nov 17 08:48:55 EST 2006
#
# chkconfig: 345 90 10
# description: Apache Tomcat is the servlet container that is used in \
#              the official Reference Implementation for the Java Servlet \
#              and JavaServer Pages technologies. 
# pidfile: /var/run/tomcat.pid
#
##############################################################################
#
#         Copyright 2004 The Apache Software Foundation.
#
#         Licensed under the Apache License, Version 2.0 (the "License");
#         you may not use this file except in compliance with the License.
#         You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
##############################################################################
#

# Import JAVA_HOME and CATALINA_HOME etc
source /etc/profile.d/tomcat.sh
source /etc/profile.d/java.sh

DAEMON_HOME=\$CATALINA_HOME/bin
TOMCAT_USER=tomcat

# for multi instances adapt those lines.
TMP_DIR=/var/tmp
PID_FILE=/var/run/tomcat.pid
CATALINA_BASE=\$CATALINA_HOME
TRUST_STORE=/etc/grid-security/truststore


CATALINA_OPTS="-Djava.endorsed.dirs=\$CATALINA_HOME/common/endorsed -Djavax.net.ssl.trustStore=\$TRUST_STORE"
CLASSPATH=\$CATALINA_HOME/bin/bootstrap.jar

case "\$1" in
	start)
		chown \$TOMCAT_USER \$CATALINA_HOME

		# create trust store
		keytool -import -noprompt -alias localhost -keystore \$TRUST_STORE -file /etc/grid-security/hostcert.pem -storepass "supersecure" >/dev/null 2>&1

		[ \$? -eq 0 ] && echo "Created trust store \$TRUST_STORE"

		\$DAEMON_HOME/jsvc \\
			-user \$TOMCAT_USER \\
			-home \$JAVA_HOME \\
			-Dcatalina.home=\$CATALINA_HOME \\
			-Djava.io.tmpdir=\$TMP_DIR \\
			-wait 10 \\
			-pidfile \$PID_FILE \\
			-outfile \$CATALINA_HOME/logs/catalina.out \\
			-errfile '&1' \\
			\$CATALINA_OPTS \\
			-cp \$CLASSPATH \\
			org.apache.catalina.startup.Bootstrap

		# To get a verbose JVM
			#-verbose \
		# To get a debug of jsvc.
			#-debug \

		exit \$?
	;;

	stop)
		\$DAEMON_HOME/jsvc \\
		-stop \\
		-pidfile \$PID_FILE \\
		org.apache.catalina.startup.Bootstrap
		exit \$?
	;;

	status)
		if PID=\$(pgrep -u root jsvc); then
			echo "tomcat (pid \$PID) is running..."
		else
			echo "tomcat is stopped"
		fi
	;;

	*)
		echo "Usage tomcat.sh start/stop/status"
		exit 1
	;;
esac

EOF


%clean
rm -rf $RPM_BUILD_ROOT

%post
chkconfig --add tomcat
mkdir -p ${PREFIX}/lib/gridpulse
echo APAC-apache-tomcat >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%preun
chkconfig --del tomcat

%postun
perl -ni -e "print unless /^APAC-apache-tomcat/;" %{PREFIX}/lib/gridpulse/system_packages.pulse

%files
%defattr(755,root,root)
/etc/rc.d/init.d/tomcat
%config /etc/profile.d/tomcat.sh
%config /etc/profile.d/tomcat.csh

%changelog
* Thu Nov 16 2006 Andrew Sharpe
- added trust store
- cleaned init script
* Tue Nov 14 2006 Andrew Sharpe
- added PREFIX and DEP
- removed source


1. Document Purpose

This deployment guide describes how to deploy SharedToken Portability Service. 
We assume STPS will be installed in the directory /opt/stps.
=============================
2.Deployment Strategy

STPS is deployed as a web application with Shibboleth protection. 
The access point will be built in ARCS Access Service, i.e. the user can access STPS by clicking on the link in AS page.  
=============================
3. Prerequisites

*	Tomcat 5.x.x or later
*	Apache 2
*	Ant 1.6.x or later
*	Shibboleth Provider 2.x 
=============================
4. Download and build

cd /opt
svn co http://projects.arcs.org.au/svn/systems/trunk/idp/stps
cd /opt/stps
ant
chown –R tomcat6:tomcat6 /opt/stps

Assume the tomcat user/tomcat group is tomcat6/tomcat6
=============================
5. Configure STPS

5.1 To sign the SharedToken Ownership Statement, you need a PKCS12 
certificate with a password protection and put it under the directory /opt/stps/conf.

The sample command to convert PEM certificate to PKCS12 is:

$openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.p12

5.2 Under /opt/stps/conf, edit the configuration files stps.properties, 
context.xml and log4j.xml and make changes to suit your environment. 

To generate a encrypted password for setting the PASSWORD in stps.properties, 
run the command under bin directory, for example:

/opt/stps/bin/java -jar stps-crypto.jar

You will be prompted to input the password that is used to protect the pkcs12 certificate. 

=============================
6. Deploy

cp /opt/stps/conf/context.xml $CATALINA_HOME/conf/Catalina/localhost/stps.xml
=============================
7. Configure Apache

7.1.	Edit /etc/httpd/conf.d/proxy_ajp.conf and add:
ProxyPass /stps ajp://localhost:8009/stps

7.2.	Edit /etc/httpd/conf.d/shib.conf

<Location /stps>
 AuthType shibboleth
  ShibRequireSession On
  ShibUseHeaders On
  require valid-user
</Location>
=============================
8. Restart Servers

For example:

restart tomat6 restart
restart httpd restart
restart shibd restart
=============================
9.Test

Access the following link in your browser and after Shibboleth login, you will see the SharedToken document.
https://stpshostname/stps/download.action
=============================


Feedback on this document should be emailed to damien.chen@arcs.org.au 
Damien Chen
Java Developer


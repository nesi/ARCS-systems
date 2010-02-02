1. Document Purpose

This deployment guide describes how to deploy SharedToken Portability Service.
=============================
2.Deployment Strategy

STPS is deployed as a web application with Shibboleth protection. The access point will be built in ARCS Access Service, i.e. the user can access STPS by clicking on the link in AS page.  
=============================
3. Prerequisites

*	Tomcat 5.x.x or later
*	Apache 2
*	Ant 1.6.x or later
*	Shibboleth Provider 2.x 
=============================
4. Download

cd /opt
svn co http://projects.arcs.org.au/svn/systems/trunk/idp/stps
=============================
5. Configure STPS

Edit the configuration files under /opt/stps/conf and make changes to suit your environment. 

The sample command to convert PEM certificate to PKCS12 is:

$openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.p12
=============================
6. Build

cd /opt/stps
ant
chown –R tomcat6:tomcat6 /opt/stps

Assume the tomcat user/tomcat group is tomcat6/tomcat6
=============================
7. Deploy

cp /opt/stps/conf/context.xml $CATALINA_HOME/conf/Catalina/localhost/stps.xml
=============================
8. Configure Apache

8.1.	Edit /etc/httpd/conf.d/proxy_ajp.conf and add:
ProxyPass /stps ajp://localhost:8009/stps

8.2.	Edit /etc/httpd/conf.d/shib.conf

<Location /stps>
 AuthType shibboleth
  ShibRequireSession On
  ShibUseHeaders On
  require valid-user
</Location>
=============================
9. Restart Servers

For example:

restart tomat6 restart
restart httpd restart
restart shibd restart
=============================
10.Test

Access the following link in your browser and after Shibboleth login, you will see the SharedToken document.
https://stpshostname/stps/download.action
=============================


Feedback on this document should be emailed to damien.chen@arcs.org.au 
Damien Chen
Java Developer


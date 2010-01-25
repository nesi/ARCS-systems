1. Document Purpose

This deployment guide describes how to deploy SharedToken Portability Service.

2. Deployment Strategy

STPS is deployed as a web application with Shibboleth protection. The access point will be built in ARCS Access Service, i.e. the user can access STPS by clicking on the link in AS page.  

3. Prerequisites
 * Tomcat 5.x.x or later
 * Apache 2
 * Ant 1.6.x or later
 * Shibboleth Provider 2.x 

4. Download

$cd /tmp
$svn co http://projects.arcs.org.au/svn/systems/trunk/idp/stps

5. Configure STPS

5.1	Edit the properties file /tmp/stps/src/stps-web.properties and make changes to suit your environment. 
{{{
#the issuer who generates and releases the SharedToken document
ISSUER=ARCS

#the Federation-trusted certificate used for signing the document, must be in PKCS12 format 
CERTIFICATE=/usr/share/tomcat/webapps/stps/WEB-INF/classes/sample_signing_cert.p12
#the password to protect the certificate
PASSWORD=secret

#the mapping of the Shibboleth headers
HTTP_HEADER_NAME_SHAREDTOKEN=auEduPersonSharedToken
HTTP_HEADER_NAME_CN=cn
HTTP_HEADER_NAME_MAIL=mail
HTTP_HEADER_NAME_PROVIDER_ID=Shib-Identity-Provider
}}}

The command to convert PEM certificate to PKCS12 is:

$openssl pkcs12 -export -in idp.crt -inkey idp.key -out cred.p12

5.2	Edit the logging file /tmp/stps/src/stps-web.properties and make changes to suit your environment.
{{{
…
log4j.appender.STPS.File=/usr/share/tomcat/logs/stps.log
…
log4j.logger.au.org.arcs.stps=DEBUG,STPS
…
}}}

6. Build and Deploy

$cd /tmp/stps
$ant war
$cp dist/stps.war $TOMCAT_HOME/webapps/

7. Configure Apache
7.1	Edit /etc/httpd/conf.d/proxy_ajp.conf and add:
ProxyPass /stps ajp://localhost:8009/stps
7.2	Edit /etc/httpd/conf.d/shib.conf
{{{
<Location /stps>
 AuthType shibboleth
  ShibRequireSession On
  ShibUseHeaders On
  require valid-user
</Location>
}}}

8. Restart Servers
For example:
$restart tomat6 restart
$restart httpd restart
$restart shibd restart

9. Test
Access the following link in your browser and after Shibboleth login, you will see the  SharedToken document.
https://stpshostname/stps/download.action

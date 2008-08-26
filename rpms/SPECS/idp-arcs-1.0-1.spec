Summary: Installs sofwtare necessary for an IdP
Name: idp-arcs
Version: 1.0
Release: 1
Source: idp-arcs-1.0.tar.gz
License: ARCS
Group: Applications/Development
Prefix: /
#Requires: httpd, mod_ssl, tomcat5, ntp, shibboleth-idp
Requires: shibboleth-idp

%description
Installs the shibboleth-idp software

%prep
%setup -q

%install
cp -r * %{prefix}

%files
/etc/httpd/conf.d/proxy_ajp.conf.idp
/etc/httpd/conf.d/ssl-443.conf
/etc/httpd/conf.d/ssl-8443.conf
/etc/certs/ca.pem
%defattr(-,tomcat,tomcat)
/var/lib/tomcat5/webapps/shibboleth-idp/WEB-INF/lib/

%pre
service tomcat5 restart

%post
hn=`hostname --fqdn`

sed --in-place -e "s/MY_DNS/${hn}/g" /etc/httpd/conf.d/ssl-443.conf
sed --in-place -e "s/MY_DNS/${hn}/g" /etc/httpd/conf.d/ssl-8443.conf

[ -f /etc/httpd/conf.d/proxy_ajp.conf ] && mv /etc/httpd/conf.d/proxy_ajp.conf /etc/httpd/conf.d/proxy_ajp.conf.rpmsave

mv /etc/httpd/conf.d/proxy_ajp.conf.idp /etc/httpd/conf.d/proxy_ajp.conf

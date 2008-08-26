Summary: Installs sofwtare necessary for an IdP
Name: shibboleth-idp
Version: 1.3.3
Release: 1
Source: shibboleth-idp-1.3.3.tar.gz
License: ARCS
Group: Applications/Development
Prefix: /
#Requires: java-1.5.0-sun, java-1.5.0-sun-devel
Requires: httpd, mod_ssl, tomcat5, ntp, java-1.5.0-sun, java-1.5.0-sun-devel

%description
Installs the shibboleth-idp software

%prep
%setup -q

%install
cp -r * %{prefix}

%files
%defattr(-,tomcat,tomcat)
/usr/local/shibboleth-idp/
/var/lib/tomcat5/webapps/shibboleth-idp.war

%post
hn=`hostname --fqdn`

sed --in-place -e "s/MY_DNS/${hn}/g" /usr/local/shibboleth-idp/etc/idp.xml

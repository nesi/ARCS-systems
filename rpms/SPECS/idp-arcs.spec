Summary: Configures shibboleth IdP for ARCS member
Name: idp-arcs
Version: 1.0
Release: 2arcs
Source: idp-arcs-1.0.tar.gz
License: ARCS
Group: Applications/Development
Requires: shibboleth-idp >= 1.3.3
BuildRoot: %{_tmppath}/%{name}-%{version}-buildroot

%description
Configure shibboleth-idp for ARCS member sites

%prep
%setup -q

%install
install -m 755 -d ${RPM_BUILD_ROOT}/etc/pki/tls/private
install -m 755 -d ${RPM_BUILD_ROOT}/etc/pki/tls/certs
install -m 755 -d ${RPM_BUILD_ROOT}/etc/cron.hourly
install -m 755 -d ${RPM_BUILD_ROOT}/usr/local/shibboleth-idp/etc
install -m 755 -d ${RPM_BUILD_ROOT}/etc/httpd/conf.d
install -m 755 -d ${RPM_BUILD_ROOT}/etc/tomcat5
install -m 755 -d ${RPM_BUILD_ROOT}/var/lib/tomcat5/webapps/shibboleth-idp/WEB-INF

install -m 640 testfed-keystore.jks ${RPM_BUILD_ROOT}/etc/pki/tls/private/
install -m 644 level-1-ca.crt ${RPM_BUILD_ROOT}/etc/pki/tls/certs/
install -m 755 idp-metadata ${RPM_BUILD_ROOT}/etc/cron.hourly/
install -m 644 level-1-metadata.xml ${RPM_BUILD_ROOT}/usr/local/shibboleth-idp/etc/
install -m 644 ssl-federation.conf ${RPM_BUILD_ROOT}/etc/httpd/conf.d/
install -m 644 web.xml ${RPM_BUILD_ROOT}/var/lib/tomcat5/webapps/shibboleth-idp/WEB-INF/
install -m 644 login.jsp ${RPM_BUILD_ROOT}/var/lib/tomcat5/webapps/shibboleth-idp/
install -m 644 login-error.jsp ${RPM_BUILD_ROOT}/var/lib/tomcat5/webapps/shibboleth-idp/
install -m 644 proxy_ajp.conf ${RPM_BUILD_ROOT}/etc/httpd/conf.d/proxy_ajp.conf-arcs
install -m 644 server.xml ${RPM_BUILD_ROOT}/etc/tomcat5/server.xml-arcs
install -m 644 idp.xml ${RPM_BUILD_ROOT}/usr/local/shibboleth-idp/etc/idp.xml-arcs
install -m 644 resolver.ldap.xml ${RPM_BUILD_ROOT}/usr/local/shibboleth-idp/etc/resolver.ldap.xml-arcs

%files
/etc/pki/tls/private/testfed-keystore.jks
/etc/pki/tls/certs/level-1-ca.crt
/etc/cron.hourly/idp-metadata
/etc/httpd/conf.d/ssl-federation.conf
/etc/httpd/conf.d/proxy_ajp.conf-arcs
%defattr(-,tomcat,tomcat)
/usr/local/shibboleth-idp/etc/idp.xml-arcs
/usr/local/shibboleth-idp/etc/resolver.ldap.xml-arcs
/usr/local/shibboleth-idp/etc/level-1-metadata.xml
/etc/tomcat5/server.xml-arcs
/var/lib/tomcat5/webapps/shibboleth-idp/WEB-INF/web.xml
/var/lib/tomcat5/webapps/shibboleth-idp/login.jsp
/var/lib/tomcat5/webapps/shibboleth-idp/login-error.jsp

%pre
if [ -f /var/lib/tomcat5/webapps/shibboleth-idp.war -a \
   ! -d /var/lib/tomcat5/webapps/shibboleth-idp ]; then
     mkdir /var/lib/tomcat5/webapps/shibboleth-idp
     pushd /var/lib/tomcat5/webapps/shibboleth-idp
     jar -xf ../shibboleth-idp.war
     popd
     chown -R tomcat:tomcat /var/lib/tomcat5/webapps/shibboleth-idp
fi

%post

if [ -f /etc/pki/tls/certs/level-1-ca.crt ]; then
  pushd /etc/pki/tls/certs
    ln -sf level-1-ca.crt `openssl x509 -hash -noout -in level-1-ca.crt`.0
  popd
fi

if [ -f /etc/pki/tls/certs/localhost.crt -a \
   ! -f /etc/pki/tls/certs/idp-federation.crt ]; then
    cp /etc/pki/tls/certs/localhost.crt \
       /etc/pki/tls/certs/idp-federation.crt
    chmod 644 /etc/pki/tls/certs/idp-federation.crt
fi

if [ -f /etc/pki/tls/private/localhost.key -a \
   ! -f /etc/pki/tls/private/idp-federation.key ]; then
    cp /etc/pki/tls/private/localhost.key \
       /etc/pki/tls/private/idp-federation.key
    chmod 640 /etc/pki/tls/private/idp-federation.key
    chgrp tomcat /etc/pki/tls/private/idp-federation.key
fi

for each in \
  /etc/httpd/conf.d/proxy_ajp.conf \
  /usr/local/shibboleth-idp/etc/idp.xml \
  /usr/local/shibboleth-idp/etc/resolver.ldap.xml \
  /etc/tomcat5/server.xml
do
  if [ ! -f ${each}-dist ]; then
     mv ${each} ${each}-dist
  fi

  mv ${each}-arcs ${each}
done

hn=`hostname --fqdn`
dn=`hostname --domain`
ou=`echo $dn | awk -F\. \
   '{printf("ou=People"); for(i=1;i<=NF;i++){printf(",dc=%s", $i);}}'`

sed --in-place \
  -e "s/MY_DNS/${hn}/g" \
  -e "s/MY_DOMAIN/${dn}/g" \
  /usr/local/shibboleth-idp/etc/idp.xml

sed --in-place \
  -e "s/MY_DNS/${hn}/g" \
  -e "s/MY_DOMAIN/${dn}/g" \
  -e "s/MY_OU/${ou}/g" \
  /usr/local/shibboleth-idp/etc/resolver.ldap.xml

sed --in-place \
  -e "s/MY_DOMAIN/${dn}/g" \
  -e "s/MY_OU/${ou}/g" \
  /etc/tomcat5/server.xml

cat <<EOF
shibboleth configured with the following site specific info:

hostname         ${hn}
domain           ${dn}
ldap-server      ldap://ldap.${dn}:389
ldap-search-base ${ou}
ldap-proxy-user  cn=proxyuser,${ou}
ldap-proxy-pass  password
providerId       urn:mace:federation.org.au:testfed:${hn}

update following files to correct anything above.

  /etc/tomcat5/server.xml
  /usr/local/shibboleth-idp/etc/idp.xml
  /usr/local/shibboleth-idp/etc/resolver.ldap.xml
EOF

%changelog
* Thu Aug 28 2008 Youzhen Cheng <Youzhen.Cheng@arcs.org.au>
- First build


%define PREFIX /usr/local/share

Summary: User mapping tool for grid certificates to local user mappings
Name: APAC-gateway-usermapping-tool
version: 0.2
release: 1
License: apache
Group: Applications/Internet
Source: %{name}-%{version}.tgz
BuildRoot: /tmp/%{name}-buildroot
Requires: APAC-mod_auth_pam, php, mod_ssl
BuildArch: noarch

%description
User Mapping tool to add grid user certificates to local system user mappings. This install assumes you have your CA and CRL's in /etc/grid-security/certificates

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}

cp -a mapfile $RPM_BUILD_ROOT%{PREFIX}
cp -a auth $RPM_BUILD_ROOT%{PREFIX}/authtool

mkdir -p $RPM_BUILD_ROOT/etc/httpd/conf.d
cp ssl.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/ssl.conf.apac
cp ssl_authtool.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/ssl_authtool.conf
cp mod_rewrite_authtool.conf $RPM_BUILD_ROOT/etc/httpd/conf.d
cp mapfile.conf $RPM_BUILD_ROOT/etc/httpd/conf.d


%clean
rm -rf $RPM_BUILD_ROOT

%post
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.orig
mv /etc/httpd/conf.d/ssl.conf.apac /etc/httpd/conf.d/ssl.conf
chkconfig httpd on

%postun
mv /etc/httpd/conf.d/ssl.conf.orig /etc/httpd/conf.d/ssl.conf

%files
%defattr(-,apache,apache)
%config(noreplace) %{PREFIX}/authtool/config.php
%config(noreplace) %{PREFIX}/mapfile/mapfile
%config(noreplace) %{PREFIX}/mapfile/mapfileconf
%config(noreplace) /etc/httpd/conf.d/ssl_authtool.conf
%config(noreplace) /etc/httpd/conf.d/mod_rewrite_authtool.conf
%config(noreplace) /etc/httpd/conf.d/mapfile.conf
%dir %{PREFIX}/authtool
%dir %{PREFIX}/mapfile
%{PREFIX}/authtool/index.php
/etc/httpd/conf.d/ssl.conf.apac

%changelog
* Tue Jan 30 2007 Ashley Wright
- changes to mapfileconf
- implemented track and trace fix for apache.
* Thu Nov 16 2006 Andrew Sharpe
- running the authtool on port 1443, all other ports on server with /auth
- url get rewritten to 1443
* Wed Nov 15 2006 Andrew Sharpe
- removed .htaccess in favour of server config
- http://httpd.apache.org/docs/2.0/howto/htaccess.html#when
- added rewrite in authtool.conf to protect passwords
* Tue Nov 14 2006 Andrew Sharpe
- added ssl.conf and authtool.conf
- using a BuildRoot
- removed mod_auth_pam
* Thu Aug 24 2006 Ashley Wright <a2.wright@qut.edu.au>
- Changed mapfile & mapfileconf to noreplace configs
* Thu Aug 17 2006 Ashley Wright <a2.wright@qut.edu.au>
- Changed file permissions for /var/www/html/


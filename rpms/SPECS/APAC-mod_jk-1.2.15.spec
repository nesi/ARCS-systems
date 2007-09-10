%define package_name mod_jk

Summary: Tomcat mod_jk connector
Name: APAC-mod_jk
Version: 1.2.15
Release: 3
License: Apache
Group: Applications/Internet
Source0: mod_jk-1.2.15-src.tar.gz
Patch: mod_jk-1.2.15.patch
BuildRoot: /tmp/%{package_name}-buildroot
Buildrequires: apr-devel, httpd-devel >= 2.0
Requires: httpd, APAC-apache-tomcat

%description
Tomcat Worker Module: A Tomcat worker is a Tomcat instance that is waiting to execute servlets on behalf of some web server. For example, we can have a web server such as Apache forwarding servlet requests to a Tomcat process (the worker) running behind it.

%prep
%setup -q -D -n %{package_name}-%{version}
%patch

%build
cd jk/native
make

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/httpd/modules
cp jk/native/apache-2.0/mod_jk.so $RPM_BUILD_ROOT/etc/httpd/modules

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/httpd/modules/mod_jk.so

%changelog
* Mon Nov 13 2006 Andrew Sharpe
- remove references to jk.workers.properties and jk.conf
* Thu Aug 31 2006 Ashley Wright <a2.wright@qut.edu.au>
- Marked jk.workers.properties and jk.conf as config files.


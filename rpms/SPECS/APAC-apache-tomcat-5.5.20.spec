%define package_name apache-tomcat
%define PREFIX /usr/local

Summary: Apache Tomcat is a servlet container for the Java Servlet and JavaServer Pages technologies.
Name: APAC-%{package_name}
Version: 5.5.20
Release: 1
Copyright: Apache
Group: Applications/Internet
Source0: %{package_name}-%{version}.tar.gz
Source1: %{package_name}-%{version}-compat.tar.gz
Source2: %{package_name}-%{version}-admin.tar.gz
BuildRoot: /tmp/%{package_name}-buildroot
Requires: jdk

%description
Apache Tomcat is the servlet container that is used in the official Reference Implementation for the Java Servlet and JavaServer Pages technologies. The Java Servlet and JavaServer Pages specifications are developed by Sun under the Java Community Process.

%prep
%setup -q -n %{package_name}-%{version}
%setup -q -T -D -b 1 -n %{package_name}-%{version}
%setup -q -T -D -b 2 -n %{package_name}-%{version}

# only because of jsvc
find . -type f | sed -e "s|^\.|%{PREFIX}/%{package_name}|" > files.list
find . -type d | sed -e "s|^\.|%dir %{PREFIX}/%{package_name}|" >> files.list
cd bin
tar zxf jsvc.tar.gz

%build
source /etc/profile
cd bin/jsvc-src
sh ./configure
make

%install
cp bin/jsvc-src/jsvc bin
rm -rf bin/jsvc-src
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
cp -R * $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
rm $RPM_BUILD_ROOT%{PREFIX}/%{package_name}/files.list

%clean
rm -rf $RPM_BUILD_ROOT

# attempt at getting correct directory ownership
%files -f files.list
%defattr(-,tomcat,tomcat)
%config %{PREFIX}/%{package_name}/conf/tomcat-users.xml
%doc %{PREFIX}/%{package_name}/LICENSE
%doc %{PREFIX}/%{package_name}/NOTICE
%doc %{PREFIX}/%{package_name}/RELEASE-NOTES
%doc %{PREFIX}/%{package_name}/RUNNING.txt

%pre
groupadd -f -r tomcat 
useradd -m -g tomcat -r tomcat || :

%post
# fix file permissions!
#chown tomcat:tomcat %{PREFIX}/%{package_name}
#chown tomcat:tomcat %{PREFIX}/%{package_name}/bin

%postun
# userdel?

%changelog
* Thu Nov 16 2006 Andrew Sharpe
- changed name from apache-tomcat to APAC-apache-tomcat
* Mon Nov 13 2006 Andrew Sharpe
- removed all init references
- added the jsvc package
* Thu Aug 30 2006 Ashley Wright <a2.wright@qut.edu.au>
- /init.d/tomcat - Fixed bug finding common/endorsed
* Thu Aug 17 2006 Ashley Wright <a2.wright@qut.edu.au>
- /init.d/tomcat Now sources /etc/profile
* Thu Jul 7 2006 Ashley Wright <a2.wright@qut.edu.au>
- Added export of CATALINA_HOME
* Thu Jul 6 2006 Ashley Wright <a2.wright@qut.edu.au>
- Added httpd to requires.
* Thu Apr 27 2006 Ashley Wright <a2.wright@qut.edu.au>
- Modifications to include init.d and profile.d files
* Thu Apr 20 2006 Ashley Wright <a2.wright@qut.edu.au>
- Initial creation of spec file and rpm

%package jsvc
Group: Applications/System
Summary: Java daemon utility
Requires: APAC-apache-tomcat
%description jsvc
Provides the java startup daemon, jsvc

%files jsvc
%defattr(755,tomcat,tomcat)
%{PREFIX}/%{package_name}/bin/jsvc


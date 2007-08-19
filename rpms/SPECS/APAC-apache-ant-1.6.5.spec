%define package_name apache-ant
%define PREFIX /usr/local

Summary: A Java-based build tool like make
Name: APAC-apache-ant
Version: 1.6.5
Release: 1
Copyright: Apache
Group: Applications/Internet
#Source0: APAC-gateway-config-tomcat.tgz
Source: %{package_name}-%{version}-bin.tar.gz
BuildRoot: /tmp/%{package_name}-buildroot
Requires: jdk
BuildArch: noarch

%description
A system independent (i.e. not shell-based) build tool that uses XML files as "Makefiles".

For more information see http://ant.apache.org/index.html.

%prep
%setup -q -n %{package_name}-%{version}

%install
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
cp -R * $RPM_BUILD_ROOT%{PREFIX}/%{package_name}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/%{package_name}

%changelog
* Thu Nov 16 2006 Andrew Sharpe
- changed from apache-ant to APAC-apache-ant


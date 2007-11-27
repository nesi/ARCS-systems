Summary: NG2 rpm to provide the basics for an APAC NG2 service
Name: APAC-gateway-ng2
Version: 1.1
Release: 3
License: APAC
Group: Applications/Internet
Requires: APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper, inetd
Source: vdt-config.ng2.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic ng2 functionality

%prep
tar zxf %_sourcedir/vdt-config.ng2.tar.gz

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
install vdt-config.ng2 $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.ng2

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Nov 27 2007 Russell Sim
- added requirement, inetd which is required for gridftp
* Thu Sep 27 2007 Russell Sim
- refactored spec to be cleaner and use a more generic build root
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch
- Updated source URL.


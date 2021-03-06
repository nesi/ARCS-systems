Summary: Provides basic ngdata functionality
Name: APAC-gateway-ngdata
Version: 1.1
Release: 3
License: APAC or QUT?
Group: Applications/Internet
Requires: APAC-globus-gridftp-server, APAC-globus-gsi-openssh-server, ca_APAC, APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-gateway-gridmap-sync, APAC-gateway-host-certificates
Source: vdt-config.ngdata.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
This is a meta RPM to pull in the dependencies for basic ngdata functionality

%post
chkconfig xinetd on

%prep
tar zxf %_sourcedir/vdt-config.ngdata.tar.gz

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
install vdt-templates/vdt-config.ngdata $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.ngdata

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Jan 22 2008 Russell Sim
- changed to reflect default base path in tarball
- added tarball to source rpm
* Thu Sep 27 2007 Russell Sim
- refactored spec to be cleaner and use a more generic build root
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch
- Updated source URL.


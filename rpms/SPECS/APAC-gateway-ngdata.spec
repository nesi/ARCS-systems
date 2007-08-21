%define source http://www.grid.apac.edu.au/repository/svn/systems/trunk/rpms/SOURCES/scripts/vdt-templates/vdt-config.ngdata

Summary: Provides basic ngdata functionality
Name: APAC-gateway-ngdata
Version: 1.1
Release: 2
Copyright: APAC or QUT?
Source: %{source}
Group: Applications/Internet
Requires: APAC-globus-gridftp-server, APAC-globus-gsi-openssh-server, ca_APAC, APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-gateway-gridmap-sync, APAC-gateway-host-certificates
BuildArch: noarch
BuildRoot: /tmp/%{name}-buildroot

%description
This is a meta RPM to pull in the dependencies for basic ngdata functionality

%post
chkconfig xinetd on

%prep
wget %{source} -O %_sourcedir/vdt-config.ngdata 2> /dev/null

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_sourcedir/vdt-config.ngdata $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.ngdata

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch
- Updated source URL.


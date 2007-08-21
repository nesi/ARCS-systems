%define source http://www.grid.apac.edu.au/repository/svn/systems/trunk/rpms/SOURCES/scripts/vdt-templates/vdt-config.ng2

Summary: NG2 rpm to provide the basics for an APAC NG2 service
Name: APAC-gateway-ng2
Version: 1.1
Release: 2
Copyright: APAC
Source: %{source}
Group: Applications/Internet
Requires: APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper
BuildArch: noarch
BuildRoot: /tmp/%{name}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic ng2 functionality

%prep
wget %{source} -O %_sourcedir/vdt-config.ng2 2> /dev/null

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_sourcedir/vdt-config.ng2 $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.ng2

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch
- Updated source URL.


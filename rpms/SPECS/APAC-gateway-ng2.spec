Summary: NG2 rpm to provide the basics for an APAC NG2 service
Name: APAC-gateway-ng2
Version: 1.1
Release: 2
License: APAC
Group: Applications/Internet
Requires: APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper
BuildArch: noarch
BuildRoot: /tmp/%{name}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic ng2 functionality

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_sourcedir/sources/vdt-template/vdt-config.ng2 $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.ng2

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch
- Updated source URL.


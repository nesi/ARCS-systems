Summary: GUMS rpm to provide the basics for an APAC GUMS service
Name: APAC-gateway-nggums
Version: 1.0
Release: 1
Copyright: APAC
Group: Applications/Internet
Requires: APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper
BuildArch: noarch
BuildRoot: /tmp/%{name}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic nggums functionality

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_sourcedir/scripts/vdt-tempate/vdt-config.nggums $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.nggums

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Mon Sep 10 2007
- Updated package to build with new repos layout


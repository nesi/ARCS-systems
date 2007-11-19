Summary: GUMS rpm to provide the basics for an APAC GUMS service
Name: APAC-gateway-nggums
Version: 1.0
Release: 2
License: APAC
Group: Applications/Internet
Requires: APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper
Source: vdt-config.nggums.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic nggums functionality

%prep
tar zxf %_sourcedir/vdt-config.nggums.tar.gz

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_builddir/vdt-config.nggums $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.nggums

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Thu Sep 27 2007 Russell Sim
- refactored spec to be cleaner and use a more generic build root
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout


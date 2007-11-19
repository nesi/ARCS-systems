Summary: Scripts to help the installation and configuration of the VDT for the APAC Grid
Name: APAC-gateway-vdt-helper
Version: 0.1
Release: 3
License: APAC
Group: Applications/Internet
Requires: /bin/sh, rpm, coreutils, grep, perl, sed, sudo
Source: vdt-helper.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
Install requirements for the VDT (http://vdt.cs.wisc.edu/) and provides helper scripts to install the VDT.

%prep
tar zxf %_sourcedir/vdt-helper.tar.gz

%build
#cd %_sourcedir/vdt-helper/vdt_helper

%install
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) /usr/local/sbin/vdt-install-helper
%doc /usr/local/share/doc/vdt-helper/vdt-config.example

%changelog
* Wed Sep 26 2007 Russell Sim
- Updated spec to copy the script to the build dir
- Updated spec to clean correctly after building
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch

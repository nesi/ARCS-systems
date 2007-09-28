Summary: Scripts to help the installation and configuration of the VDT for the APAC Grid
Name: APAC-gateway-vdt-helper
Version: 0.1
Release: 3
License: APAC
Group: Applications/Internet
Requires: /bin/sh, rpm, coreutils, grep, perl, sed, sudo
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
Install requirements for the VDT (http://vdt.cs.wisc.edu/) and provides helper scripts to install the VDT.

%build
cp -a %_sourcedir/scripts/vdt-helper/* $RPM_BUILD_DIR
make

%install
make DESTDIR=$RPM_BUILD_ROOT/usr/local install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) /usr/local/sbin/vdt-install-helper
%doc /usr/local/share/doc/*

%changelog
* Wed Sep 26 2007 Russell Sim
- Updated spec to copy the script to the build dir
- Updated spec to clean correctly after building
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch

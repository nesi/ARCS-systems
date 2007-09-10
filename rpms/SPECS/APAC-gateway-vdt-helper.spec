Summary: Scripts to help the installation and configuration of the VDT for the APAC Grid
Name: APAC-gateway-vdt-helper
Version: 0.1
Release: 2
Copyright: APAC
Group: Applications/Internet
Requires: /bin/sh, rpm, coreutils, grep, perl, sed, sudo
BuildArch: noarch

%description
Install requirements for the VDT (http://vdt.cs.wisc.edu/) and provides helper scripts to install the VDT.

%build
cd %_sourcedir/vdt-helper/vdt_helper
make

%install
make install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) /usr/local/sbin/vdt-install-helper

%changelog
* Mon Sep 10 2007
- Updated package to build with new repos layout
* Wed Aug 22 2007 Ashley Wright
- Merged Russell's branch

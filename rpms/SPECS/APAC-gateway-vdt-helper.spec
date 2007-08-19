%define TARBALL_URL http://ng0.hpc.jcu.edu.au/cgi-bin/svn_tarball?repo=http://auriga.qut.edu.au/svn/apac/gateway/scripts&dir=vdt_helper&rev=241&tmout=10

Summary: Scripts to help the installation and configuration of the VDT for the APAC Grid
Name: APAC-gateway-vdt-helper
Version: 0.1
Release: 1
Copyright: APAC
Source: vdt_helper.tgz
Group: Applications/Internet
Requires: /bin/sh, rpm, coreutils, grep, perl, sed, sudo
BuildArch: noarch

%description
Install requirements for the VDT (http://vdt.cs.wisc.edu/) and provides helper scripts to install the VDT.

Source available from %{TARBALL_URL}

%prep
%setup -n vdt_helper

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/sbin

cp vdt-install.sh $RPM_BUILD_ROOT/usr/local/sbin/vdt-install-helper
chmod +x $RPM_BUILD_ROOT/usr/local/sbin/vdt-install-helper

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
/usr/local/sbin/vdt-install-helper

%changelog


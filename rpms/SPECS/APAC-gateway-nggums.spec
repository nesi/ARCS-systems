Summary: GUMS rpm to provide the basics for an APAC GUMS service
Name: APAC-gateway-nggums
Version: 1.0
Release: 4
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
cp %_builddir/vdt-templates/vdt-config.nggums $RPM_BUILD_ROOT/usr/local/etc

mkdir -p $RPM_BUILD_ROOT/usr/local/share/doc
cp %_builddir/vdt-templates/gums.config $RPM_BUILD_ROOT/usr/local/share/doc

mkdir -p $RPM_BUILD_ROOT/etc/grid-security/http/
ln -s /etc/grid-security/hostcert.pem $RPM_BUILD_ROOT/etc/grid-security/http/httpcert.pem
ln -s /etc/grid-security/hostkey.pem $RPM_BUILD_ROOT/etc/grid-security/http/httpkey.pem


%files
/usr/local/etc/vdt-config.nggums
%doc /usr/local/share/doc/gums.config

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Jan 22 2008 Russell Sim
- changed to reflect default base path in tarball
* Thu Jan 17 2008 Russell Sim
- added symlinks required by vdt install of apache
* Fri Nov 23 2007 Russell Sim
- Added gums.config file from gbuild scripts to package
* Thu Sep 27 2007 Russell Sim
- refactored spec to be cleaner and use a more generic build root
* Mon Sep 10 2007 Russell Sim
- Updated package to build with new repos layout


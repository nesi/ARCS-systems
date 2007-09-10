Summary: Cron job to update CRLs
Name: APAC-gateway-config-globus_CA
Version: 0.1
Release: 1
License: GPL
Group: Applications/Internet
Requires: ca_APAC, APAC-CA-config
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs the APAC CA as the default globus CA.

%install
HASH="1e12d831"
rm -rf $RPM_BUILD_ROOT

mkdir -p $RPM_BUILD_ROOT/etc/grid-security/certificates
ln -sf /etc/grid-security/certificates/host-ssl.conf.$HASH $RPM_BUILD_ROOT/etc/grid-security/globus-host-ssl.conf
ln -sf /etc/grid-security/certificates/user-ssl.conf.$HASH $RPM_BUILD_ROOT/etc/grid-security/globus-user-ssl.conf
ln -sf /etc/grid-security/certificates/grid-security.conf.$HASH $RPM_BUILD_ROOT/etc/grid-security/grid-security.conf

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/grid-security/globus-host-ssl.conf
/etc/grid-security/globus-user-ssl.conf
/etc/grid-security/grid-security.conf

%changelog


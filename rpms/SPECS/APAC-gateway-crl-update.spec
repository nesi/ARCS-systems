%define PREFIX /usr/local

Summary: Cron job to update CRLs
Name: APAC-gateway-crl-update
Version: 0.1
Release: 1
Copyright: GPL
Group: Applications/Internet
Requires: fetch-crl, ca_APAC, crontabs
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs a Certificate Revokation List(crl) retrieval cron script to update select crls hourly.

%install
HASH="1e12d831"
rm -rf $RPM_BUILD_ROOT

mkdir -p $RPM_BUILD_ROOT/etc/cron.hourly
cat <<EOF > $RPM_BUILD_ROOT/etc/cron.hourly/05-get-crl
#!/bin/sh

BASE=/etc/grid-security
INPUT_DIR=\$BASE/hourly_crls
CERT_DIR=\$BASE/certificates

/usr/sbin/fetch-crl --loc \$INPUT_DIR --out \$CERT_DIR --quiet

EOF

mkdir -p $RPM_BUILD_ROOT/etc/cron.daily
cat <<EOF > $RPM_BUILD_ROOT/etc/cron.daily/05-get-crl
#!/bin/sh

BASE=/etc/grid-security
INPUT_DIR=\$BASE/certificates
CERT_DIR=\$INPUT_DIR

/usr/sbin/fetch-crl --loc \$INPUT_DIR --out \$CERT_DIR --quiet

EOF

mkdir -p $RPM_BUILD_ROOT/etc/grid-security/hourly_crls
ln -sf /etc/grid-security/certificates/$HASH.0 $RPM_BUILD_ROOT/etc/grid-security/hourly_crls
ln -sf /etc/grid-security/certificates/$HASH.crl_url $RPM_BUILD_ROOT/etc/grid-security/hourly_crls

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p %{PREFIX}/lib/gridpulse
echo %{name} >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^%{name}/;" %{PREFIX}/lib/gridpulse/system_packages.pulse

%files
%defattr(755,root,root)
/etc/grid-security/hourly_crls
/etc/cron.hourly/05-get-crl
/etc/cron.daily/05-get-crl

%changelog


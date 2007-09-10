%define PREFIX /usr/local

Summary: Sets up mod_jk for the gateway environment
Name: APAC-gateway-config-mod_jk
Version: 0.1
Release: 1
License: APAC or JCU?
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
Requires: APAC-mod_jk
BuildArch: noarch

%description
Sets up mod_jk for the gateway environment

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/httpd/{conf,conf.d}

cat <<EOF > $RPM_BUILD_ROOT/etc/httpd/conf/jk.workers.properties
worker.list=ajp13
worker.ajp13.port=8009
worker.ajp13.host=localhost
worker.ajp13.type=ajp13
EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/httpd/conf.d/mod_jk.conf
LoadModule jk_module    modules/mod_jk.so
JkWorkersFile   conf/jk.workers.properties
JkLogFile       logs/mod_jk.log
JkExtractSSL On
JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
JkRequestLogFormat "%w %V %T"
JkMount /gridsphere/* ajp13
JkMount /manager/* ajp13
#JkMount /webappX/* ajp13
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(766,root,root)
%config /etc/httpd/conf/jk.workers.properties
%config /etc/httpd/conf.d/mod_jk.conf

%post
service httpd reload || :

mkdir -p %{PREFIX}/lib/gridpulse
echo APAC-mod_jk >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^APAC-mod_jk/;" %{PREFIX}/lib/gridpulse/system_packages.pulse


%changelog
* Wed Nov 15 2006 Andrew Sharpe
- removed source


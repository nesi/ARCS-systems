%define PREFIX /usr/local
%define DEP apache-ant

Summary: Ant configuration for APAC gateways
Name: APAC-gateway-config-ant
Version: 0.1
Release: 3
Copyright: APAC
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
Requires: APAC-apache-ant
BuildArch: noarch

%description
Adds ANT_HOME environment variable for APAC gateways

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/profile.d
cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/ant.sh
export ANT_HOME="%{PREFIX}/%{DEP}"
export PATH="\$ANT_HOME/bin:\$PATH"
EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/ant.csh
setenv ANT_HOME "%{PREFIX}/%{DEP}"
setenv PATH "\$ANT_HOME/bin:\$PATH"
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p %{PREFIX}/lib/gridpulse
echo APAC-apache-ant >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^APAC-apache-ant/;" %{PREFIX}/lib/gridpulse/system_packages.pulse

%files
%defattr(755,root,root)
/etc/profile.d/ant.sh
/etc/profile.d/ant.csh

%changelog
* Mon Apr 16 2007 Ashley Wright
- Fixed path to system_packages.pulse
* Wed Nov 15 2006 Andrew Sharpe
- removed source file, put contents in install


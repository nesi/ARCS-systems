Summary: Creates the gridmap file hourly based on VOMS and the APAC usermapping tool
Name: APAC-gateway-gridmap-gen
Version: 0.1
Release: 1
License: APAC
Group: Applications/Internet
Requires: edg-mkgridmap, APAC-gateway-usermapping-tool
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs a cron script to create /etc/grid-security/grid-mapfile hourly based on data from VOMS and the usermapping tool

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/cron.hourly

cat <<EOF > $RPM_BUILD_ROOT/etc/cron.hourly/01-gridmap-gen
#!/bin/sh

[ -x /opt/edg/sbin/edg-mkgridmap ] && /opt/edg/sbin/edg-mkgridmap --conf=/usr/local/share/mapfile/mapfileconf --output=/usr/local/share/mapfile/grid-mapfile --safe

EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
/etc/cron.hourly/01-gridmap-gen

%post
mkdir -p /usr/local/lib/gridpulse
echo %{name} >> /usr/local/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^%{name}/;" /usr/local/lib/gridpulse/system_packages.pulse

%changelog
* Wed Nov 15 2006 Andrew Sharpe
- removed source


%changelog
* Tue Nov 14 2006 Andrew Sharpe
- refactored to use the edg-mkgridmap rpm
- removed source
* Thu Aug 24 2006 Ashley Wright <a2.wright@qut.edu.au>
- Removed /etc/grid-security/edg-tools/edg-mkgridmap
* Thu Aug 18 2006 Ashley Wright <a2.wright@qut.edu.au>
- Moved VOMRS stuff to this RPM


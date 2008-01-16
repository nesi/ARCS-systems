%define PREFIX /usr/local

Summary: The APAC CA certificates and crl tool
Name: APAC-gateway-gridpulse
Version: 0.2
Release: 7
Source: %{name}-%{version}.tgz
License: GPL
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
Requires: /usr/bin/Mail, smtpdaemon, vixie-cron
BuildArch: noarch

%description
Installs the APAC gridpulse script and cron entry to report on gateway health.

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/bin
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/lib

cp gridpulse $RPM_BUILD_ROOT%{PREFIX}/bin
cp -a lib $RPM_BUILD_ROOT%{PREFIX}/lib/gridpulse

perl -pi -e "s|\\\$PREFIX|%{PREFIX}|g" $RPM_BUILD_ROOT%{PREFIX}/bin/gridpulse

%clean
rm -rf $RPM_BUILD_ROOT

%post
#if upgrade remove first
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" %{PREFIX}/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v %{PREFIX}/bin/gridpulse | crontab
fi

# if the root crontab doesn't exist or doesn't contain gridpulse add it.
if [ ! -e /var/spool/cron/root ] || ! grep -q %{PREFIX}/bin/gridpulse /var/spool/cron/root; then
	echo "3,23,43 * * * * %{PREFIX}/bin/gridpulse grid_pulse@gridaus.org.au >/dev/null 2>&1" >> /var/spool/cron/root
/etc/init.d/crond status >> /dev/null
	# if cron isn't running just start it
	if [ "$?" -eq "3" ]
	then
		/etc/init.d/crond start
	else
		/etc/init.d/crond restart
	fi
fi

echo %{name} >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" %{PREFIX}/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v %{PREFIX}/bin/gridpulse | crontab
fi

%files
%defattr(644,root,root)
%attr(755,root,root) %{PREFIX}/bin/gridpulse
%{PREFIX}/lib/gridpulse

%changelog
* Wed Jan 16 2008 Russell Sim
- changed gridpulse email address
- updates scripts to be more careful when upgrading


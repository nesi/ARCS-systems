%define PREFIX /usr/local

Summary: The ARCS health reporting tool.
Name: APAC-gateway-gridpulse
Version: 0.2
Release: 8
Source: gridpulse.tar.gz
License: GPL
Group: Applications/Internet
BuildRoot: %{_tmppath}/%{name}-buildroot
Prefix:	/usr/local
Requires: /usr/bin/Mail, smtpdaemon, vixie-cron
Provides: Gpulse = 1.1
Conflicts: Gpulse < 1.1
BuildArch: noarch


%description
Installs the ARCS gridpulse script and cron entry to report on gateway health. Reports from all systems are collected by the GOC http://goc.grid.apac.edu.au/.


%prep
tar zxf %_sourcedir/gridpulse.tar.gz


%install
mkdir -p $RPM_BUILD_ROOT/usr/local/bin
mkdir -p $RPM_BUILD_ROOT/usr/local/lib/gridpulse
mkdir -p $RPM_BUILD_ROOT/usr/local/share/doc/gridpulse

# TODO these should be either using the prefix to install or using the makefile
# install gridpulse/gridpulse $RPM_BUILD_ROOT/%{_prefix}/etc
# or
# PREFIX=%{_prefix} make install

install gridpulse/gridpulse $RPM_BUILD_ROOT/usr/local/bin/
install gridpulse/system_shorts.pulse $RPM_BUILD_ROOT/usr/local/lib/gridpulse/
install gridpulse/README $RPM_BUILD_ROOT/usr/local/share/doc/gridpulse/

# this needs to be fixed? PREFIX is only defined when the RPM is installed!
# possibly belongs in post install?
#perl -pi -e "s|\\\$PREFIX|%{PREFIX}|g" $RPM_BUILD_ROOT%{PREFIX}/bin/gridpulse


%clean
rm -rf $RPM_BUILD_ROOT


%post
#if upgrade remove first
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v $RPM_INSTALL_PREFIX0/bin/gridpulse | crontab
fi

# if the root crontab doesn't exist or doesn't contain gridpulse add it.
if [ ! -e /var/spool/cron/root ] || ! grep -q $RPM_INSTALL_PREFIX0/bin/gridpulse /var/spool/cron/root; then
	echo "3,23,43 * * * * $RPM_INSTALL_PREFIX0/bin/gridpulse grid_pulse@gridaus.org.au >/dev/null 2>&1" >> /var/spool/cron/root
/etc/init.d/crond status >> /dev/null
	# if cron isn't running just start it
	if [ "$?" -eq "3" ]
	then
		/etc/init.d/crond start
	else
		/etc/init.d/crond restart
	fi
fi

echo %{name} >> $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse


%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v $RPM_INSTALL_PREFIX0/bin/gridpulse | crontab
fi


%files
%defattr(644,root,root)
%attr(755,root,root) /usr/local/bin/gridpulse
/usr/local/lib/gridpulse
%doc /usr/local/share/doc/gridpulse/README


%changelog
* Tue Jan 22 2008 Russell Sim
- changed install to use install command
- added README file
- added source tar.gz file so that source rpms are useful
* Mon Jan 21 2008 Daniel Cox
- add conflict for old Gpulse package, also provide Gpulse (for gbuild scripts)
- remove reference to PREFIX variable (after testing Gbuild.spec)
- updated description
- system_packages.pulse is not required, since maintained by post scripts
* Wed Jan 16 2008 Russell Sim
- changed gridpulse email address
- updates scripts to be more careful when upgrading


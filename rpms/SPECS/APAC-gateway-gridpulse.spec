Summary:	The ARCS health reporting tool.
Name:		APAC-gateway-gridpulse
Version:	0.2
Release:	13
Source:		gridpulse.tar.gz
License:	GPL
Group:		Applications/Internet
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch
Prefix:		/usr/local
Requires:	/usr/bin/Mail, smtpdaemon, vixie-cron, perl
Provides:	Gpulse = 1.1
Obsoletes:	Gpulse < 1.1

%description
Installs the ARCS gridpulse script and cron entry to report on gateway health. Reports from all systems are collected by the GOC http://goc.grid.apac.edu.au/.

%prep
%setup -n gridpulse

%install
# For software that has a proper Makefile:
# PREFIX=%{prefix} make install

# The Makefile of most ARCS packages, simply creates SOURCES/package.tar.gz
install -D gridpulse $RPM_BUILD_ROOT%{prefix}/bin/gridpulse
install -D system_shorts.pulse $RPM_BUILD_ROOT%{prefix}/lib/gridpulse/system_shorts.pulse
install -D README $RPM_BUILD_ROOT%{prefix}/share/doc/gridpulse/README


%clean
rm -rf $RPM_BUILD_ROOT


%post
#if upgrade remove first
# TODO: modifying system_packages.pulse is a common theme
#  we should have a tool to manage it and reduce complexity of these scripts
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v $RPM_INSTALL_PREFIX0/bin/gridpulse | crontab
fi
echo %{name} >> $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse

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


%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
	crontab -l | grep -v $RPM_INSTALL_PREFIX0/bin/gridpulse | crontab
fi


%files
%defattr(644,root,root)
%attr(755,root,root) %{prefix}/bin/gridpulse
%{prefix}/lib/gridpulse
%doc %{prefix}/share/doc/gridpulse/README


%changelog
* Tue Jan 29 2008 Daniel Cox
- use Obsoletes instead of Conflicts
* Mon Jan 22 2008 Daniel Cox
- make sure gridpulse runs on the Xen host with no errors
- monitor free memory, RAID and NPTL status
- show vdt version
- add conflict for old Gpulse package, also provide Gpulse (just in case)
- fix use of PREFIX variable (after testing Gbuild.spec)
- updated description
- system_packages.pulse is not required, since maintained by post scripts
* Tue Jan 22 2008 Russell Sim
- changed install to use install command
- added README file
- added source tar.gz file so that source rpms are useful
* Wed Jan 16 2008 Russell Sim
- changed gridpulse email address
- updates scripts to be more careful when upgrading


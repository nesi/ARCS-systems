Summary:	APAC-specific configuration files and scripts for Grid Gateways
Name:		Ggateway
Version:	1.0.1
Release:	11
License:	GNU
Group:		Grid/Deployment
BuildRoot:	%{_tmppath}
BuildArch:	noarch
Requires: 	logrotate perl mktemp smtpdaemon

%description
Provide local configuration files and scripts for use
when building Grid Gateway machines at APAC sites.

%pre
for F in pbs.pm.APAC pbs.pm.APAC-GT2 ; do
  [ -f /usr/local/src/$F ] && /bin/cp -p /usr/local/src/$F /usr/local/src/$F.`/bin/date +%s` || :
done

%install
%files
%defattr(-,root,root)
/

%post
mkdir -p /usr/local/lib/gridpulse
cat /usr/local/lib/gridpulse/system_packages.pulse 2>/dev/null | grep "^Ggateway$" >/dev/null ||
  echo Ggateway >>/usr/local/lib/gridpulse/system_packages.pulse

%preun
echo ".. executing pre-uninstall script with parameter: $1"
[ "$1" -ge 1 ] && exit 0
TF=`mktemp` || exit 1
grep -v "^Ggateway$" </usr/local/lib/gridpulse/system_packages.pulse >$TF 2>/dev/null
cp $TF /usr/local/lib/gridpulse/system_packages.pulse

%changelog
* Tue Apr 21 2009 Darran Carey <darran.carey@arcs.org.au>
- changed email address from grid_pulse@vpac.org to
  grid_pulse@arcs.org.au in /etc/logrotate.d/grid.

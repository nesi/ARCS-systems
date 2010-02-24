Summary:	APAC-specific configuration files and scripts for Grid Gateways
Name:		Ggateway
Version:	1.0.2
Release:	2
License:	GNU
Group:		Grid/Deployment
Source0:	Ggateway-1.0.2.tgz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}
BuildArch:	noarch
Requires: 	logrotate perl mktemp smtpdaemon

%description
Provide local configuration files and scripts for use
when building Grid Gateway machines at APAC sites.

%prep
%setup -q
%pre
for F in pbs.pm.APAC pbs.pm.APAC-GT2 ; do
  [ -f /usr/local/src/$F ] && /bin/cp -p /usr/local/src/$F /usr/local/src/$F.`/bin/date +%s` || :
done

%install
# At this poimt $RPM_BUILD_ROOT will be something like /var/tmp/Ggateway-1.0.2-2
# That is where files to be included in the RPM should go
# 
# The current directory will be rpms/BUILD/Ggateway-1.0.2
# And that is where the files are extracted

# We need to 
# * create the RPM_BUILD_ROOT directory if it doesn't exist yet
# * wipe out its contents if any
# * copy the contents of the current directory into the build directory
# * populate the RPM_BUILD_ROOT directory
# 

if [ -n "$RPM_BUILD_ROOT" ] ; then
  rm -rf "$RPM_BUILD_ROOT"
  mkdir -p $RPM_BUILD_ROOT
  echo "I'm in `pwd`"
  ls -la
  cp -R * $RPM_BUILD_ROOT
fi

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
* Thu Feb 25 2010 Vladimir Mencl <vladimir.mencl@canterbury.ac.nz>
- actually make this SPEC file work - was building empty RPMs
* Wed Feb 24 2010 Vladimir Mencl <vladimir.mencl@canterbury.ac.nz>
- patched auditquery to report only completed jobs (not to break Globus 4.0.8)
- bumped up version # to 1.0.2
* Tue Apr 21 2009 Darran Carey <darran.carey@arcs.org.au>
- changed email address from grid_pulse@vpac.org to
  grid_pulse@arcs.org.au in /etc/logrotate.d/grid.

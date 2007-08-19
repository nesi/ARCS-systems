Summary:	APAC-specific build/update scripts for Grid machines
Name:		Gbuild
Version:	1.0.1
Release:	23
License:	GNU
Group:		Grid/Deployment
BuildRoot:	/home/graham/rpmbuild/redhat/BUILD/%{name}-buildroot
BuildArch:	noarch
Requires: 	logrotate perl mktemp smtpdaemon

%description
Provides local scripts for use when building Grid machines at APAC sites.

%install
%files
%defattr(-,root,root)
/

%post
mkdir -p /usr/local/lib/gridpulse
cat /usr/local/lib/gridpulse/system_packages.pulse 2>/dev/null | grep "^Gbuild$" >/dev/null ||
  echo Gbuild >>/usr/local/lib/gridpulse/system_packages.pulse

%preun
echo ".. executing pre-uninstall script with parameter: $1"
[ "$1" -ge 1 ] && exit 0
TF=`mktemp` || exit 1
grep -v "^Gbuild$" </usr/local/lib/gridpulse/system_packages.pulse >$TF 2>/dev/null
cp $TF /usr/local/lib/gridpulse/system_packages.pulse

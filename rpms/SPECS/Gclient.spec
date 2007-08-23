Summary:	APAC-specific configuration files and scripts for Grid Client
Name:		Gclient
Version:	1.0.1
Release:	7
License:	GNU
Group:		Grid/Deployment
BuildRoot:	/home/graham/rpmbuild/redhat/BUILD/%{name}-buildroot
BuildArch:	noarch
Requires: 	openssl wget util-linux vixie-cron

%description
Provide local configuration files and scripts for use
when building Grid Client machines at APAC sites.

%install
%files
%defattr(-,root,root)
/

%post
mkdir -p /usr/local/lib/gridpulse
cat /usr/local/lib/gridpulse/system_packages.pulse 2>/dev/null | grep "^Gclient$" >/dev/null ||
  echo Gclient >>/usr/local/lib/gridpulse/system_packages.pulse

%preun
echo ".. executing pre-uninstall script with parameter: $1"
[ "$1" -ge 1 ] && exit 0
TF=`mktemp` || exit 1
grep -v "^Gclient$" </usr/local/lib/gridpulse/system_packages.pulse >$TF 2>/dev/null
cp $TF /usr/local/lib/gridpulse/system_packages.pulse

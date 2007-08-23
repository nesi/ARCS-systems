Summary:	APAC Grid Pulse Generator
Name:		Gpulse
Version:	1.0.1
Release:	8
License:	GNU
Group:		Applications/System
BuildRoot:	/home/graham/rpmbuild/redhat/BUILD/%{name}-buildroot
BuildArch:	noarch
Requires: 	vixie-cron gawk sed openssl mailx smtpdaemon mktemp

%description
The APAC Grid Pulse Generator emits an email at 20-minute
intervals containing current system status details.

%install
%files
%defattr(-,root,root)
/

%post
TF=`mktemp` || exit 1
( crontab -l 2>/dev/null | grep -v /usr/local/bin/gridpulse.sh
  echo "3,23,43 * * * * /usr/local/bin/gridpulse.sh >/dev/null 2>&1 || :" ) >$TF
crontab $TF && echo ".. gridpulse.sh has been added to root crontab!"
mkdir -p /usr/local/lib/gridpulse
cat /usr/local/lib/gridpulse/system_packages.pulse 2>/dev/null | grep "^Gpulse$" >/dev/null ||
  echo Gpulse >>/usr/local/lib/gridpulse/system_packages.pulse

%preun
echo ".. executing pre-uninstall script with parameter: $1"
[ "$1" -ge 1 ] && exit 0
TF=`mktemp` || exit 1
crontab -l 2>/dev/null | grep -v /usr/local/bin/gridpulse.sh                >$TF
crontab $TF && echo ".. gridpulse.sh has been removed from root crontab!"
grep -v "^Gpulse$" </usr/local/lib/gridpulse/system_packages.pulse >$TF 2>/dev/null
cp $TF /usr/local/lib/gridpulse/system_packages.pulse

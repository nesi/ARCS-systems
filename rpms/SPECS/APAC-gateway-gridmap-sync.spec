Summary: Retrieves the gridmap file from a remote location via a cron job
Name: APAC-gateway-gridmap-sync
Version: 0.1
Release: 1
Copyright: APAC
Group: Applications/Internet
Requires: wget, util-linux
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs a cron script to create /etc/grid-security/grid-mapfile hourly from a remote grid-mapfile

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/cron.hourly

cat <<EOF > $RPM_BUILD_ROOT/etc/cron.hourly/01-gridmap-sync
#!/bin/sh

# Customize these variables for your location
OPTIONS="--no-verbose"
LOCAL_MAP="/etc/grid-security/grid-mapfile"
LOCAL_MAP_NEW="\$LOCAL_MAP-new"
REMOTE_MAP="http://ngportal/mapfile/grid-mapfile"

# Remote mapfile generation was probably started at same time as this;
# give it time to complete, then download mapfile
PATH=/usr/bin:/bin
sleep 30; message=\`wget \$OPTIONS -O \$LOCAL_MAP_NEW \$REMOTE_MAP 2>&1\`

# Check download success, move mapfile into place
[ \$? = 0 ] && mv -f \$LOCAL_MAP_NEW \$LOCAL_MAP && touch \$LOCAL_MAP && exit 0
logger -t gridmap-local "Error retrieving mapfile: \$message" && exit 0 && exit 1

EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
/etc/cron.hourly/01-gridmap-sync

%post
mkdir -p /usr/local/lib/gridpulse
echo %{name} >> /usr/local/lib/gridpulse/system_packages.pulse

# custom remote gridmap location
[ -n "$REMOTE_GRIDMAP" ] && perl -pi -e "s|^(REMOTE_MAP=).*|\1\"$REMOTE_GRIDMAP\"|" /etc/cron.hourly/01-gridmap-sync || :

%postun
perl -ni -e "print unless /^%{name}/;" /usr/local/lib/gridpulse/system_packages.pulse

%changelog
* Tue Nov 14 2006 Andrew Sharpe
- refactored to use the edg-mkgridmap rpm
- removed source
* Thu Aug 24 2006 Ashley Wright <a2.wright@qut.edu.au>
- Removed /etc/grid-security/edg-tools/edg-mkgridmap
* Thu Aug 18 2006 Ashley Wright <a2.wright@qut.edu.au>
- Moved VOMRS stuff to this RPM


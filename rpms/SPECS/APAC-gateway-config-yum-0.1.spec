Summary: Yum configuration for APAC gateways
Name: APAC-gateway-config-yum
Version: 0.1
Release: 2
Copyright: Apache
Group: Applications/Internet
Requires: yum
Buildroot: /tmp/%{name}-builtroot
BuildArch: noarch

%description
Adds dries, edg-util and eugridpma yum repositories

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/yum.repos.d

cat <<EOF > $RPM_BUILD_ROOT/etc/yum.repos.d/edg-util.repo
[edg-util]
name=edg-util
baseurl=http://www.eugridpma.org/distribution/util/
gpgcheck=0
enabled=1

EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/yum.repos.d/eugridpma.repo
[eurogridpma]
name=EUGridPMA
baseurl=http://www.eugridpma.org/distribution/igtf/current
gpgkey=http://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3
gpgcheck=1
enabled=1

EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/yum.repos.d/dries.repo
[dries]
name=Extra Fedora rpms dries - $releasever - $basearch
baseurl=http://ftp.belnet.be/packages/dries.ulyssis.org/redhat/el4/en/i386/dries/RPMS
gpgkey=http://dries.ulyssis.org/rpm/RPM-GPG-KEY.dries.txt
gpgcheck=1
enabled=1

EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root)
/etc/yum.repos.d/edg-util.repo
/etc/yum.repos.d/eugridpma.repo
/etc/yum.repos.d/dries.repo

%changelog


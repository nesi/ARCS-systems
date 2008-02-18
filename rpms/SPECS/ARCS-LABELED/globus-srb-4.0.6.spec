%define PREFIX /usr/srb
%define major_version 4.0
%define minor_version 6
%define GLOBUS_LOCATION %{PREFIX}/globus

Summary:        Parts of globus package for ARCS use
Name:           globus-srb
Version:        %{major_version}.%{minor_version}
Release:        1.arcs
Group:          Applications/Internet
License:        Globus
Source:         http://www-unix.globus.org/ftppub/gt4/%{major_version}/%{version}/installers/src/gt%{version}-all-source-installer.tar.bz2
URL:            http://www-unix.globus.org
Buildrequires:  gcc, perl, ant
BuildRoot:      /tmp/%{name}-%{version}-buildroot

%description
Parts of globus package for ARCS use

%prep
%setup -q -n gt%{version}-all-source-installer

 
%build
# do incremental build so we can get file lists
export GLOBUS_LOCATION=$RPM_BUILD_ROOT%{PREFIX}/globus
./configure --disable-webmds --disable-wstests --disable-tests --disable-wsc --disable-wscas --disable-rendezvous --enable-prewsmds --disable-rls --disable-wsjava --disable-wsmds --disable-wsdel --disable-wsrft --disable-wsgram --prefix=$GLOBUS_LOCATION

make globus-gsi

find $GLOBUS_LOCATION > globus-gsi.list

make gridftp globus_gridftp_server-thr

find $GLOBUS_LOCATION > gridftp.list

$GLOBUS_LOCATION/sbin/gpt-postinstall

%install
GLOBUS_LOCATION=$RPM_BUILD_ROOT%{PREFIX}/globus

# make some moves
for i in globus-gridftp-server ; do
    mv $GLOBUS_LOCATION/sbin/$i $GLOBUS_LOCATION/libexec
done

# unwanted cruft on a large scale
for i in doc endorsed man setup test lib/*.jar; do
    rm -rf $GLOBUS_LOCATION/$i
done

# unwanted cruft on a smaller scale
for i in $GLOBUS_LOCATION/libexec/*; do
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-gridftp-server" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/sshd" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/sftp-server" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/myproxy-" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-bootstrap.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/gpt-bootstrap.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-build-env-gcc32dbgpthr.sh" ]] && continue
  rm -rf $i
done

for i in $GLOBUS_LOCATION/sbin/*; do
    [[ $i =~ "$GLOBUS_LOCATION/sbin/gpt*" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/sbin/libtool-gcc32dbgpthr" ]] && continue
    rm -rf $i
done

for i in $GLOBUS_LOCATION/bin/*; do
    [[ $i =~ "$GLOBUS_LOCATION/bin/grid-proxy-" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/myproxy-" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/globus-url-copy" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/gsis" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/globusrun-ws" ]] && continue
    rm -rf $i
done

mkdir -p $RPM_BUILD_ROOT/etc/xinetd.d


cat <<EOF > $GLOBUS_LOCATION/libexec/globus-run-cmd
#!/bin/sh

PROG="\$(basename \$0)"

export GLOBUS_LOCATION="%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.sh

exec \$GLOBUS_LOCATION/libexec/\$PROG \$@
EOF

chmod +x $GLOBUS_LOCATION/libexec/globus-run-cmd



mkdir -p $GLOBUS_LOCATION/sbin

for i in sbin/globus-gridftp-server ; do
    ln -sf %{PREFIX}/globus/libexec/globus-run-cmd $GLOBUS_LOCATION/$i
done


ln -sf /etc/ssh $GLOBUS_LOCATION/etc/ssh

# profile setup
mkdir -p $RPM_BUILD_ROOT/etc/profile.d

find $RPM_BUILD_ROOT/usr/srb/globus/lib -name '*la' -exec sh -c 'cat $1 | sed "s|/tmp/globus-srb-4.0.6-buildroot||g" > $1.bak && mv $1.bak $1' {} {} \; ;

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%doc %{PREFIX}/globus/GLOBUS_LICENSE
%dir %{PREFIX}/globus


%package config
Group: Applications/System
Summary: Globus proxy utilities
Requires: globus-srb
%description config
Provides the globus etc directory

%files config
%defattr(755,root,root)
#/etc/profile.d/globus.sh
#/etc/profile.d/globus.csh
%{PREFIX}/globus/etc/*

%post config
if ! rpm -qa | grep globus-config ; then
cat << EOF > /etc/profile.d/globus.sh
export GLOBUS_LOCATION="%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.sh
EOF

cat << EOF > /etc/profile.d/globus.csh
setenv GLOBUS_LOCATION "%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.csh
EOF
chmod 755 /etc/profile.d/globus.csh
chmod 755 /etc/profile.d/globus.sh
fi

%package libraries
Group: Applications/System
Summary: Globus libraries
Prereq: /sbin/ldconfig
Requires: globus-srb
%description libraries
Provides the globus libraries

%files libraries
%defattr(-,root,root)
%{PREFIX}/globus/lib/*[!perl]
%{PREFIX}/globus/libexec/globus-run-cmd
%dir %{PREFIX}/globus/libexec
%{PREFIX}/globus/include

%post libraries
if ! grep -q %{GLOBUS_LOCATION}/lib /etc/ld.so.conf; then
	echo "%{GLOBUS_LOCATION}/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

%package proxy-utils
Group: Applications/System
Summary: Globus proxy utilities
Requires: globus-srb-libraries, globus-srb-config
%description proxy-utils
Provides the globus proxy-utils, ie grid-proxy-*

%files proxy-utils
%defattr(755,root,root)
%{PREFIX}/globus/bin/grid-proxy-*

%package gridftp-srb-dsi-dependencies
Group: Applications/System
Summary: Files required by the gridFTP SRB DSI
Requires: globus-srb-gridftp-server
%description gridftp-srb-dsi-dependencies
Provides the files required by the gridFTP SRB DSI

%files gridftp-srb-dsi-dependencies
%defattr(755,root,root)
%{PREFIX}/globus/libexec/globus-bootstrap.sh
%{PREFIX}/globus/libexec/gpt-bootstrap.sh
%{PREFIX}/globus/share/*
%{PREFIX}/globus/var/*
#%{PREFIX}/globus/etc/gpt/*
#%{PREFIX}/globus/etc/globus_core/*
#%{PREFIX}/globus/etc/globus_packages/*
%{PREFIX}/globus/lib/perl/*
%{PREFIX}/globus/sbin/gpt*
%{PREFIX}/globus/sbin/libtool-gcc32dbgpthr
%{PREFIX}/globus/libexec/globus-build-env-gcc32dbgpthr.sh


%package gridftp-server
Group: Applications/System
Summary: Globus gridftp server
Requires: globus-srb-libraries, globus-srb-config, xinetd
%description gridftp-server
Provides the globus gridftp server

%files gridftp-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/globus-gridftp-server
%{PREFIX}/globus/libexec/globus-gridftp-server
%{PREFIX}/globus/libexec/globus-bootstrap.sh
%{PREFIX}/globus/libexec/gpt-bootstrap.sh

%package gridftp-client
Group: Applications/System
Summary: Globus gridftp client
Requires: globus-srb-libraries, globus-srb-config, globus-srb-proxy-utils
%description gridftp-client
Provides the globus gridftp client

%files gridftp-client
%defattr(755,root,root)
%{PREFIX}/globus/bin/globus-url-copy

%post gridftp-client
if ! grep -q ^gsiftp /etc/services; then
	cat <<-EOF >> /etc/services
		gsiftp  2811/tcp        # Globus GridFTP
		gsiftp  2811/udp        # Globus GridFTP
	EOF
fi

%changelog
* Tue Feb 12 2008 Florian Goessmann <florian@ivec.org>
- added xinetd dependency for gridftp-server
* Mon Feb 11 2008 Florian Goessmann <florian@ivec.org>
- split into two globus package lines, one for use with SRB on for PRIMA
  this is the one for SRB, built with non-threaded gridFTP
* Wed Jan 30 2008 Florian Goessmann <florian@ivec.org>
- added changelog
- change naming scheme according to ARCS standards


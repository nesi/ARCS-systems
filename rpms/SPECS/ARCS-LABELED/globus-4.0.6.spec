%define PREFIX /usr
%define major_version 4.0
%define minor_version 6
%define GLOBUS_LOCATION %{PREFIX}/globus

Summary:        Parts of globus package for ARCS use
Name:           globus
Version:        %{major_version}.%{minor_version}
Release:        4.arcs
Group:          Applications/Internet
License:        Globus
Source:         http://www-unix.globus.org/ftppub/gt4/%{major_version}/%{version}/installers/src/gt%{version}-all-source-installer.tar.bz2
URL:            http://www-unix.globus.org
Buildrequires:  compat-gcc-34, perl, ant, perl-XML-Parser
BuildRoot:      /tmp/%{name}-%{version}-%{release}-buildroot

%description
Parts of globus package for ARCS use

%prep
%setup -q -n gt%{version}-all-source-installer

%build
# do incremental build so we can get file lists
export GLOBUS_LOCATION=$RPM_BUILD_ROOT%{PREFIX}/globus
export CC=/usr/bin/gcc34
./configure --disable-webmds --disable-wstests --disable-tests --disable-wsc --disable-wscas --disable-rendezvous --enable-prewsmds --disable-wsjava --disable-wsmds --disable-wsdel --disable-wsrft --prefix=$GLOBUS_LOCATION
#./configure --disable-webmds --disable-wstests --disable-tests --disable-wsc --disable-wscas --disable-rendezvous --enable-prewsmds --disable-rls --disable-wsjava --disable-wsmds --disable-wsdel --disable-wsrft --disable-wsgram --prefix=$GLOBUS_LOCATION

make globus-gsi

find $GLOBUS_LOCATION > globus-gsi.list

make myproxy

find $GLOBUS_LOCATION > myproxy.list

make gsi-openssh

find $GLOBUS_LOCATION > gsi-openssh.list

make gridftp

find $GLOBUS_LOCATION > gridftp.list

make rls

find $GLOBUS_LOCATION > rls.list

make globus_globusrun_ws

find $GLOBUS_LOCATION > globusrun-ws.list

make wsgram

find $GLOBUS_LOCATION > wsgram.list


$GLOBUS_LOCATION/sbin/gpt-postinstall

make install

%install
GLOBUS_LOCATION=$RPM_BUILD_ROOT%{PREFIX}/globus

# make some moves
for i in sshd globus-gridftp-server myproxy-server myproxy-admin-query myproxy-admin-load-credential myproxy-admin-change-pass; do
    mv $GLOBUS_LOCATION/sbin/$i $GLOBUS_LOCATION/libexec
done

mv -f $GLOBUS_LOCATION/bin/ssh.d/ssh $GLOBUS_LOCATION/bin/gsissh
mv -f $GLOBUS_LOCATION/bin/ssh.d/scp $GLOBUS_LOCATION/bin/gsiscp
mv -f $GLOBUS_LOCATION/bin/ssh.d/sftp $GLOBUS_LOCATION/bin/gsisftp

mv -f $GLOBUS_LOCATION/share/myproxy/myproxy-server.config $GLOBUS_LOCATION/etc

# unwanted cruft on a large scale
# don't remove setup -> needed by rls
for i in doc endorsed man test lib/*.jar; do
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
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-build-env-gcc32dbg.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-build-env-gcc32dbgpthr.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-sh-tools-vars.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-sh-tools.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/globus-rls-reporter" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/aggrexec/aggregator-exec-test.sh" ]] && continue
  [[ $i =~ "$GLOBUS_LOCATION/libexec/aggrexec/globus-rls-aggregatorsource.pl" ]] && continue
  #[[ $i =~ "$GLOBUS_LOCATION/libexec/gcc32dbgpthr/shared/globus-rls-reporter" ]] && continue
  #[[ $i =~ "$GLOBUS_LOCATION/libexec/aggrexec" ]] && continue
  rm -rf $i
done

for i in $GLOBUS_LOCATION/sbin/*; do
    [[ $i =~ "$GLOBUS_LOCATION/sbin/gpt*" ]] && continue
    [[ $i = "$GLOBUS_LOCATION/sbin/libtool-gcc32dbg" ]] && continue
    rm -rf $i
done
#rm -rf $GLOBUS_LOCATION/sbin/libtool-gcc32dbgpthr

for i in $GLOBUS_LOCATION/bin/*; do
    [[ $i =~ "$GLOBUS_LOCATION/bin/grid-proxy-" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/myproxy-" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/globus-url-copy" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/gsis" ]] && continue
    [[ $i =~ "$GLOBUS_LOCATION/bin/globusrun-ws" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/globus-makefile-header" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/sqlite3" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/iodbctest" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/globus-rls-server" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/globus-rls-cli" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/globus-rls-admin" ]] && continue
    [[ $i == "$GLOBUS_LOCATION/bin/iodbc-config" ]] && continue
    #[[ $i =~ "$GLOBUS_LOCATION/bin/gcc32dbgpthr" ]] && continue
    rm -rf $i
done

mkdir -p $RPM_BUILD_ROOT/etc/xinetd.d

cat <<EOF > $RPM_BUILD_ROOT/etc/xinetd.d/gsiftp
service gsiftp
{
    socket_type = stream
    protocol = tcp
    wait = no
    user = root
    instances = UNLIMITED
    cps = 400 10
    env += GLOBUS_LOCATION=%{GLOBUS_LOCATION}
    env += GLOBUS_TCP_PORT_RANGE=40000,41000
    env += LD_LIBRARY_PATH=%{GLOBUS_LOCATION}/lib
    server = %{PREFIX}/globus/sbin/globus-gridftp-server
    server_args = -i
    disable = no
}
EOF


cat <<EOF > $GLOBUS_LOCATION/libexec/globus-run-cmd
#!/bin/sh

PROG="\$(basename \$0)"

export GLOBUS_LOCATION="%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.sh

exec \$GLOBUS_LOCATION/libexec/\$PROG \$@
EOF

chmod +x $GLOBUS_LOCATION/libexec/globus-run-cmd

mkdir -p $GLOBUS_LOCATION/sbin

for i in sbin/globus-gridftp-server sbin/sshd sbin/sftp-server sbin/myproxy-server sbin/myproxy-admin-query sbin/myproxy-admin-load-credential sbin/myproxy-admin-change-pass; do
    ln -sf %{PREFIX}/globus/libexec/globus-run-cmd $GLOBUS_LOCATION/$i
done


ln -sf /etc/ssh $GLOBUS_LOCATION/etc/ssh

# profile setup
mkdir -p $RPM_BUILD_ROOT/etc/profile.d

find $RPM_BUILD_ROOT/usr/globus/lib -name '*la' -exec sh -c 'cat $1 | sed "s|/tmp/globus-4.0.6-4.arcs-buildroot||g" > $1.bak && mv $1.bak $1' {} {} \; ;

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%doc %{PREFIX}/globus/GLOBUS_LICENSE
%dir %{PREFIX}/globus


%package config
Group: Applications/System
Summary: Globus proxy utilities
Requires: globus
%description config
Provides the globus etc directory

%files config
%defattr(755,root,root)
#/etc/profile.d/globus.sh
#/etc/profile.d/globus.csh
%{PREFIX}/globus/etc/*

%post config
if rpm -qa | grep globus-srb-config ; then
rm -rf /etc/profile.d/globus*
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
else
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
Requires: globus
%description libraries
Provides the globus libraries

%files libraries
%defattr(-,root,root)
%{PREFIX}/globus/lib/*[!perl]
%{PREFIX}/globus/libexec/globus-run-cmd
%{PREFIX}/globus/libexec/globus-sh-tools.sh
%{PREFIX}/globus/libexec/globus-sh-tools-vars.sh
%dir %{PREFIX}/globus/libexec
%{PREFIX}/globus/include
%{PREFIX}/globus/bin/globus-makefile-header
%{PREFIX}/globus/libexec/globus-bootstrap.sh
%{PREFIX}/globus/libexec/gpt-bootstrap.sh
%{PREFIX}/globus/share/*
%{PREFIX}/globus/var/*
%{PREFIX}/globus/lib/perl/*
%{PREFIX}/globus/sbin/gpt*
%{PREFIX}/globus/sbin/libtool-gcc32dbg
%{PREFIX}/globus/libexec/globus-build-env-gcc32dbg.sh
%{PREFIX}/globus/libexec/globus-build-env-gcc32dbgpthr.sh

%post libraries
if ! grep -q %{GLOBUS_LOCATION}/lib /etc/ld.so.conf; then
	echo "%{GLOBUS_LOCATION}/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

%package proxy-utils
Group: Applications/System
Summary: Globus proxy utilities
Requires: globus-libraries, globus-config
%description proxy-utils
Provides the globus proxy-utils, ie grid-proxy-*

%files proxy-utils
%defattr(755,root,root)
%{PREFIX}/globus/bin/grid-proxy-*

%package gridftp-server
Group: Applications/System
Summary: Globus gridftp server
Requires: globus-libraries, globus-config, xinetd
%description gridftp-server
Provides the globus gridftp server

%files gridftp-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/globus-gridftp-server
%{PREFIX}/globus/libexec/globus-gridftp-server
%{PREFIX}/globus/libexec/globus-bootstrap.sh
%{PREFIX}/globus/libexec/gpt-bootstrap.sh
%config /etc/xinetd.d/gsiftp

%post gridftp-server
if ! grep -q ^gsiftp /etc/services; then
	cat <<-EOF >> /etc/services
		gsiftp  2811/tcp        # Globus GridFTP
		gsiftp  2811/udp        # Globus GridFTP
	EOF
fi


%package gridftp-client
Group: Applications/System
Summary: Globus gridftp client
Requires: globus-libraries, globus-config, globus-proxy-utils
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


%package gsi-openssh-server
Group: Applications/System
Summary: Globus gsi-openssh server
Requires: globus-libraries, globus-config, openssh-server
%description gsi-openssh-server
Provides the globus gsi-openssh server

%files gsi-openssh-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/sshd
%{PREFIX}/globus/sbin/sftp-server
%{PREFIX}/globus/libexec/sshd
%{PREFIX}/globus/libexec/sftp-server

#%post gsi-openssh-server
#perl -pi.orig -e "s|^(Subsystem\s*sftp\s*).*|\1%{PREFIX}/globus/sbin/sftp-server.sh|i" sshd_config


%package gsi-openssh-clients
Group: Applications/System
Summary: Globus gsi-openssh clients
Requires: globus-libraries, globus-config, globus-proxy-utils
%description gsi-openssh-clients
Provides the globus gsi-openssh clients

%files gsi-openssh-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/gsis*


%package ws-clients
Group: Applications/System
Summary: Globus web services clients
Requires: globus-libraries, globus-config, globus-proxy-utils
%description ws-clients
Provides the globus web services clients

%files ws-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/globusrun-ws

%package wsgram
Group: Applications/System
Summary: Globus wsgram web service
Requires: globus-ws-clients, perl-XML-Parser
%description wsgram
Provides the globus wsgram web service

%files wsgram
%defattr(755,root,root)
%{PREFIX}/globus/client-config.wsdd
%{PREFIX}/globus/container-log4j.properties
%{PREFIX}/globus/log4j.properties
%{PREFIX}/globus/tmp/globus_wsrf_rft/deploy-jndi-config.xml
%{PREFIX}/globus/tmp/globus_wsrf_rft/globus_wsrf_rft.gar
%{PREFIX}/globus/tmp/globus_wsrf_rft/lib/globus_wsrf_rft.jar
%{PREFIX}/globus/tmp/gram-service/deploy-jndi-config-deploy.xml
%{PREFIX}/globus/tmp/gram-service/etc/globus_gram_fs_map_config.xml
%{PREFIX}/globus/tmp/gram-service/gram-service.gar
%{PREFIX}/globus/tmp/gram-service/lib/gram-service.jar

%package myproxy-server
Group: Applications/System
Summary: Myproxy server
Requires: globus-libraries, globus-config
%description myproxy-server
Myproxy server

%files myproxy-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/myproxy-*
%{PREFIX}/globus/libexec/myproxy-*


%package myproxy-clients
Group: Applications/System
Summary: Myproxy clients
Requires: globus-libraries, globus-config, globus-proxy-utils
%description myproxy-clients
Myproxy clients

%files myproxy-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/myproxy-*

%package rls
Group: Applications/System
Summary: Replica Location Service
Requires: globus-libraries, globus-config, globus-proxy-utils
%description rls
Replica Location Service

%files rls
%{PREFIX}/globus/bin/globus-rls-admin
%{PREFIX}/globus/bin/globus-rls-cli
%{PREFIX}/globus/bin/globus-rls-server
%{PREFIX}/globus/bin/iodbc-config
%{PREFIX}/globus/bin/iodbctest
%{PREFIX}/globus/bin/sqlite3
#%{PREFIX}/globus/libexec/aggrexec/aggregator-exec-test.sh
#%{PREFIX}/globus/libexec/aggrexec/gcc32dbgpthr/shared/globus-rls-aggregatorsource.pl
#%{PREFIX}/globus/libexec/aggrexec/globus-rls-aggregatorsource.pl
%{PREFIX}/globus/libexec/globus-rls-reporter
%{PREFIX}/globus/setup/*

%changelog
* Tue Mar 18 2008 Florian Goessmann <florian@ivec.org>
- added package for globus rls
* Wed Feb 27 2008 Florian Goessmann <florian@ivec.org>
- added globus-makefile-header to library package
- moved prima dependencies into libraries
* Tue Feb 12 2008 Florian Goessmann <florian@ivec.org>
- added xinetd dependency for gridftp-server
* Mon Feb 11 2008 Florian Goessmann <florian@ivec.org>
- split into two globus package lines, one for use with SRB on for PRIMA
  this is the one for PRIMA, built with non-threaded gridFTP
  this package also provides the standalone install
* Wed Jan 30 2008 Florian Goessmann <florian@ivec.org>
- added changelog
- change naming scheme according to ARCS standards


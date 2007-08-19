%define PREFIX /usr/local
%define major_version 4.0
%define minor_version 3

Summary: Parts of globus package for APAC use
Name: APAC-globus
Version: %{major_version}.%{minor_version}
Release: 1
Group: Web
License: Globus
Source: http://www-unix.globus.org/ftppub/gt4/%{major_version}/%{version}/installers/src/gt%{version}-all-source-installer.tar.bz2
URL: http://www-unix.globus.org
Buildrequires: gcc, perl
BuildRoot: /tmp/%{name}-%{version}-buildroot

%description
Parts of globus package for APAC use

%prep
%setup -q -n gt%{version}-all-source-installer

 
%build
# do incremental build so we can get file lists
export GLOBUS_LOCATION=$RPM_BUILD_ROOT%{PREFIX}/globus
./configure --disable-webmds --disable-wstests --disable-tests --disable-wsc --disable-wscas --disable-rendezvous --enable-prewsmds --disable-rls --disable-wsjava --disable-wsmds --disable-wsdel --disable-wsrft --disable-wsgram --with-flavor=gcc32dbg --prefix=$GLOBUS_LOCATION

find . -name Makefile -exec perl -pi -e "s/^THR=.*/THR=/" {} \;

make globus-gsi

find $GLOBUS_LOCATION > globus-gsi.list

make myproxy

find $GLOBUS_LOCATION > myproxy.list

make gsi-openssh

find $GLOBUS_LOCATION > gsi-openssh.list

make gridftp

find $GLOBUS_LOCATION > gridftp.list

make globus_globusrun_ws

find $GLOBUS_LOCATION > globusrun-ws.list


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
for i in doc endorsed include lib/perl man sbin setup share test var lib/*.jar; do
	rm -rf $GLOBUS_LOCATION/$i
done

# unwanted cruft on a smaller scale
for i in $GLOBUS_LOCATION/libexec/*; do
	[[ $i =~ "$GLOBUS_LOCATION/libexec/globus-gridftp-server" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/libexec/sshd" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/libexec/sftp-server" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/libexec/myproxy-" ]] && continue
	rm -rf $i
done

#for i in $GLOBUS_LOCATION/sbin/*; do
#	[[ $i =~ "$GLOBUS_LOCATION/sbin/globus-gridftp-server" ]] && continue
#	[[ $i =~ "$GLOBUS_LOCATION/sbin/sftp-server" ]] && continue
#	[[ $i =~ "$GLOBUS_LOCATION/sbin/sshd" ]] && continue
#	rm -rf $i
#done

for i in $GLOBUS_LOCATION/bin/*; do
	[[ $i =~ "$GLOBUS_LOCATION/bin/grid-proxy-" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/bin/myproxy-" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/bin/globus-url-copy" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/bin/gsis" ]] && continue
	[[ $i =~ "$GLOBUS_LOCATION/bin/globusrun-ws" ]] && continue
	rm -rf $i
done

for i in globus_core gpt globus_packages; do
	rm -rf $GLOBUS_LOCATION/etc/$i
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
	server = %{PREFIX}/globus/sbin/globus-gridftp-server
	server_args = -i
	disable = yes
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

cat << EOF > $RPM_BUILD_ROOT/etc/profile.d/globus.sh
export GLOBUS_LOCATION="%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.sh
EOF

cat << EOF > $RPM_BUILD_ROOT/etc/profile.d/globus.csh
setenv GLOBUS_LOCATION "%{PREFIX}/globus"
source \$GLOBUS_LOCATION/etc/globus-user-env.csh
EOF



%clean
#rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%doc %{PREFIX}/globus/GLOBUS_LICENSE
%dir %{PREFIX}/globus


%package config
Group: Applications/System
Summary: Globus proxy utilities
Requires: APAC-globus, ca_APAC
%description config
Provides the globus etc directory

%files config
%defattr(755,root,root)
/etc/profile.d/globus.sh
/etc/profile.d/globus.csh
%{PREFIX}/globus/etc


%package libraries
Group: Applications/System
Summary: Globus libraries
Requires: APAC-globus
%description libraries
Provides the globus libraries

%files libraries
%defattr(-,root,root)
%{PREFIX}/globus/lib
%{PREFIX}/globus/libexec/globus-run-cmd
%dir %{PREFIX}/globus/libexec


%package proxy-utils
Group: Applications/System
Summary: Globus proxy utilities
Requires: APAC-globus-libraries, APAC-globus-config
%description proxy-utils
Provides the globus proxy-utils, ie grid-proxy-*

%files proxy-utils
%defattr(755,root,root)
%{PREFIX}/globus/bin/grid-proxy-*


%package gridftp-server
Group: Applications/System
Summary: Globus gridftp server
Requires: APAC-globus-libraries, APAC-globus-config
%description gridftp-server
Provides the globus gridftp server

%files gridftp-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/globus-gridftp-server
%{PREFIX}/globus/libexec/globus-gridftp-server
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
Requires: APAC-globus-libraries, APAC-globus-config, APAC-globus-proxy-utils
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
Requires: APAC-globus-libraries, APAC-globus-config, openssh-server
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
Requires: APAC-globus-libraries, APAC-globus-config, APAC-globus-proxy-utils
%description gsi-openssh-clients
Provides the globus gsi-openssh clients

%files gsi-openssh-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/gsis*


%package ws-clients
Group: Applications/System
Summary: Globus web services clients
Requires: APAC-globus-libraries, APAC-globus-config, APAC-globus-proxy-utils
%description ws-clients
Provides the globus web services clients

%files ws-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/globusrun-ws


%package myproxy-server
Group: Applications/System
Summary: Myproxy server
Requires: APAC-globus-libraries, APAC-globus-config
%description myproxy-server
Myproxy server

%files myproxy-server
%defattr(755,root,root)
%{PREFIX}/globus/sbin/myproxy-*
%{PREFIX}/globus/libexec/myproxy-*


%package myproxy-clients
Group: Applications/System
Summary: Myproxy clients
Requires: APAC-globus-libraries, APAC-globus-config, APAC-globus-proxy-utils
%description myproxy-clients
Myproxy clients

%files myproxy-clients
%defattr(755,root,root)
%{PREFIX}/globus/bin/myproxy-*



%define GLOBUS_LOCATION /usr/globus
%define SRB_INSTALL_DIR /usr/srb

Summary:    gridFTP_SRB_DSI
Name:       gridFTP_SRB_DSI
Version:    0.28
Release:    1
License:    Custom
Group:      Applications/File
Source:     gridftp_srb_dsi-%{version}.tar.gz
Patch:      gridftp_srb_dsi-0.28-auto_command.patch
Packager:   Florian Goessmann <florian@ivec.org>
Buildroot:  %{_tmppath}/%{name}-root
BuildRequires:  make gcc
Requires:   APAC-globus-gridftp-srb-dsi-dependencies, srb-server
%description
Interface for gridFTP to SRB

%prep
%setup -q -n globus_srb_dsi-%{version}

%patch0 -p1 -b .auto_command.patch

%build
export GLOBUS_LOCATION=%{GLOBUS_LOCATION}
export LD_LIBRARY_PATH=$GLOBUS_LOCATION/lib
./bootstrap
./configure --with-srb-path=%{SRB_INSTALL_DIR} --with-flavor=gcc32dbgpthr
make

%install
make install

mkdir -p $RPM_BUILD_ROOT/usr
mkdir -p $RPM_BUILD_ROOT/usr/globus
mkdir -p $RPM_BUILD_ROOT/%{GLOBUS_LOCATION}/etc
mkdir -p $RPM_BUILD_ROOT/%{GLOBUS_LOCATION}/etc/globus_packages
mkdir -p $RPM_BUILD_ROOT/%{GLOBUS_LOCATION}/lib
cp -pr $GLOBUS_LOCATION/etc/globus_packages/globus_srb_dsi $RPM_BUILD_ROOT/%{GLOBUS_LOCATION}/etc/globus_packages
cp -pr $GLOBUS_LOCATION/lib/libglobus_gridftp_server_srb* $RPM_BUILD_ROOT/%{GLOBUS_LOCATION}/lib

mkdir -p $RPM_BUILD_ROOT/etc/xinetd.d
cat <<EOF > $RPM_BUILD_ROOT/etc/xinetd.d/gsiftp-srb
service gsiftp-srb
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
    env += GRIDMAP=/etc/grid-security/grid-mapfile.srb
    server = %{GLOBUS_LOCATION}/sbin/globus-gridftp-server
    server_args = -i -p 5000 -dsi srb -auth-level 4 -log-level ALL -logfile /var/log/gridftp-srb.log
    disable = no
}
EOF


%post
if ! grep -q ^gsiftp-srb /etc/services; then
	cat <<-EOF >> /etc/services
		gsiftp-srb  5000/tcp        # Globus GridFTP
		gsiftp-srb  5000/udp        # Globus GridFTP
	EOF
fi

# if [[ !$SRB_HOSTNAME_DN ]]; then
#     echo Enter the SRB Server DN
#     read SRB_HOSTNAME_DN
# fi
# 
# if [[ !$SRB_DEFAULT_RESOURCE ]]; then
#     echo Enter the default SRB resource
#     read SRB_DEFAULT_RESOURCE
# fi

export HOSTNAME=`uname -n`
cat <<EOF > %{GLOBUS_LOCATION}/etc/gridftp_srb.conf
srb_hostname $HOSTNAME:5544
EOF

cat <<EOF
Please add 
srb_hostname_dn <YOUR SERVER DN>
srb_default_resource <YOU DEFAULT RESOURCE>
to %{GLOBUS_LOCATION}/etc/gridftp_srb.conf.
If you want to use to auto command execution feature,
you will also have to add:
srb_auto_executable <THE FULL PATH OF THE EXECUTABLE>
srb_user_name <THE UNIX USER TO RUN THE EXECUTABLE>
The grid-mapfile for the SRB DSI can be found at: /etc/grid-security/grid-mapfile.srb
EOF

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
/etc/xinetd.d/gsiftp-srb
%{GLOBUS_LOCATION}/etc/globus_packages/globus_srb_dsi/*
%{GLOBUS_LOCATION}/lib/libglobus_gridftp_server_srb*
# %{GLOBUS_LOCATION}/etc/gridftp_srb.conf


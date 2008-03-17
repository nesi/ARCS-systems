Summary:        OPeNDAP Backend Server (Hyrax)
Name:           bes
Version:        3.6.0
Release:        1.arcs
License:        LGPL
Group:          Applications/Internet
Source:         %{name}-%{version}.tar.gz
#Patch:          %{name}-%{version}-makefile_server.patch
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc gcc-c++ libdap == 3.8.0
Requires:       libdap == 3.8.0

%description
OPeNDAP Backend Server (Hyrax)

%prep
%setup -q

#%patch -p1 -b .makefile_server

%build
export CFLAGS='-I/usr/local/include/libdap'
export CPPFLAGS='-I/usr/local/include/libdap'
./configure --prefix=$RPM_BUILD_ROOT/usr/local
make

%install
make install
find $RPM_BUILD_ROOT/usr/local/lib -name '*.la' -exec sh -c 'cat $1 | sed "s|/var/tmp/bes-root||g" > $1.bak && mv $1.bak $1' {} {} \; ;


%post
mv /usr/local/etc/bes/bes.conf /usr/local/etc/bes/bes.conf.bak
sed 's|/var/tmp/bes-root||g' /usr/local/etc/bes/bes.conf.bak > /usr/local/etc/bes/bes.conf
rm /usr/local/etc/bes/bes.conf.bak

mv /usr/local/bin/bes-config /usr/local/bin/bes-config.bak 
sed 's|/var/tmp/bes-root||g' /usr/local/bin/bes-config.bak  > /usr/local/bin/bes-config 
chmod a+x /usr/local/bin/bes-config
rm /usr/local/bin/bes-config.bak 

mv /usr/local/bin/besctl /usr/local/bin/besctl.bak
sed 's|/var/tmp/bes-root||g' /usr/local/bin/besctl.bak > /usr/local/bin/besctl
chmod a+x /usr/local/bin/besctl
rm /usr/local/bin/besctl.bak

mv /usr/local/bin/besctl /usr/local/bin/besctl.bak
sed 's|localstatedir=${prefix}/var|localstatedir=/var|g' /usr/local/bin/besctl.bak > /usr/local/bin/besctl
chmod a+x /usr/local/bin/besctl
rm /usr/local/bin/besctl.bak

if ! grep -q /usr/locl/lib /etc/ld.so.conf; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

%changelog
* Mon Mar 17 2008 Florian Goessmann <florian@ivec.org>
- changed for version 3.6.0


Summary:        libdap
Name:           libdap
Version:        3.7.8
Release:        1.arcs
License:        LGPL
Group:          Development/Libraries
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc gcc-c++ curl-devel zlib zlib-devel libxml2 libxml2-devel

%description
Library for OPeNDAP

%prep
%setup -q

%build
export LDFLAGS="-lz"
./configure --prefix=$RPM_BUILD_ROOT/usr/local
make

%install
make install

find $RPM_BUILD_ROOT/usr/local/lib -name '*la' -exec sh -c 'cat $1 | sed "s|/var/tmp/libdap-root||g" > $1.bak && mv $1.bak $1' {} {} \; ;

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

%changelog
* Fri Feb 15 2008 Florian Goessmann <florian@ivec.org>
- first release

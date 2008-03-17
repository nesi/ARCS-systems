Summary:        dap-server
Name:           dap-server
Version:        3.8.5
Release:        1.arcs
License:        LGPL
Group:          Applications/Internet
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc gcc-c++ libdap bes == 3.6.0
Requires:       libdap bes == 3.6.0 perl-HTML-Parser

%description
OPeNDAP front end server.

%prep
%setup -q

%build
export LD_FLAGS='-L/usr/local/lib/bes'
export CPPFLAGS='-I/usr/local/include -I/usr/local/include/libdap -I/usr/local/include/bes'
./configure --prefix=$RPM_BUILD_ROOT/usr/local
make

%install
make install

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

%changelog
* Mon Mar 17 2008 Florian Goessmann <florian@ivec.org>
- changed for version 3.8.5

Summary:        dap-server
Name:           dap-server
Version:        3.7.4
Release:        2.arcs
License:        LGPL
Group:          Applications/Internet
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc gcc-c++ libdap bes
Requires:       libdap bes perl-HTML-Parser tomcat5 tomcat5-webapps

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
* Tue Feb 19 2008 Florian Goessmann <florian@ivec.org>
- added dependency: tomcat5, tomcat5-webapps
* Fri Feb 15 2008 Florian Goessmann <florian@ivec.org>
- first release

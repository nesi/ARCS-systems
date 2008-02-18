Summary:        OPeNDAP netCDF Handler
Name:           netcdf_handler
Version:        3.7.6
Release:        1.arcs
License:        LGPL
Group:          Development/Libraries
Source:         %{name}-%{version}.tar.gz
Patch:          netcdf_handler-3.7.6-makefile.patch 
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc compat-gcc-34-g77 libdap netcdf
Requires:       bes

%description
netCDF-handler for OPeNDAP. This allows an OPeNDAP server to serve out netCDF files.

%prep
%setup -q
%patch0 -p1 -b .makefile

%build
export LDFLAGS='-L/usr/lib/gcc/i386-redhat-linux/4.1.1/ -lgfortran'
export CFLAGS='-I/usr/local/include/libdap -I/usr/local/include/bes'
export CPPFLAGS='-I/usr/local/include/libdap -I/usr/local/include/bes'
./configure --prefix=$RPM_BUILD_ROOT/usr/local
make

%install
make install

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

%changelog
* Fri Feb 15 2008 Florian Goessmann <florian@ivec.org>
- first release

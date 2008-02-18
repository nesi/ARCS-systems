Summary:        HDF4 library
Name:           HDF
Version:        4.2r2
Release:        1.arcs 
License:        custom
Group:          Development/Libraries
Source:         %{name}%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc compat-gcc-34-g77 libjpeg libjpeg-devel
Requires:       libjpeg

%description
At its lowest level, HDF is a physical file format for storing scientific data. At its highest level, HDF is a collection of utilities and applications for manipulating, viewing, and analyzing data in HDF files. Between these levels, HDF is a software library that provides high-level APIs and a low-level data interface.

%prep
%setup -q -n %{name}%{version}

%build
./configure --prefix=$RPM_BUILD_ROOT/usr/local --disable-netcdf
make

%install
make install
# clean up some conflicts with files from netcdf
rm -rf $RPM_BUILD_ROOT/usr/local/bin/ncdump
rm -rf $RPM_BUILD_ROOT/usr/local/bin/ncgen
rm -rf $RPM_BUILD_ROOT/usr/local/include/netcdf.h
rm -rf $RPM_BUILD_ROOT/usr/local/include/netcdf.inc
rm -rf $RPM_BUILD_ROOT/usr/local/share/man/man1/ncdump.1
rm -rf $RPM_BUILD_ROOT/usr/local/share/man/man1/ncgen.1

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

%changelog
* Fri Feb 15 2008 Florian Goessmann <florian@ivec.org>
- first release

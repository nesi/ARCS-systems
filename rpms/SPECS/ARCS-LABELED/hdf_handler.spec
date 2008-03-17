Summary:        OPeNDAP HDF4 Handler
Name:           hdf4_handler
Version:        3.7.8
Release:        1.arcs 
License:        LGPL
Group:          Applications/Internet
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc compat-gcc-34-g77 libdap == 3.8.0 HDF = 4.2r2
Requires:       bes libdap == 3.8.0 libgfortran

%description
HDF4-handler for OPeNDAP to allow OPeNDAP to serve out HDF4 files.

%prep
%setup -q

%build
export CFLAGS='-I/usr/local/include/libdap -I/usr/local/include/bes'
export CXXFLAGS='-I/usr/local/include/libdap -I/usr/local/include/bes'
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
- changed for version 3.7.8

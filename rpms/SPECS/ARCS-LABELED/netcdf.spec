Summary:        netCDF library
Name:           netcdf
Version:        3.6.2
Release:        1.arcs
License:        custom
Group:          Development/Libraries
Source:         %{name}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc compat-gcc-34-g77

%description
NetCDF (network Common Data Form) is a set of interfaces for array-oriented data access and a freely-distributed collection of data access libraries for C, Fortran, C++, Java, and other languages. The netCDF libraries support a machine-independent format for representing scientific data. Together, the interfaces, libraries, and format support the creation, access, and sharing of scientific data.

NetCDF data is:

* Self-Describing. A netCDF file includes information about the data it contains.
* Portable. A netCDF file can be accessed by computers with different ways of storing integers, characters, and floating-point numbers.
* Direct-access. A small subset of a large dataset may be accessed efficiently, without first reading through all the preceding data.
* Appendable. Data may be appended to a properly structured netCDF file without copying the dataset or redefining its structure.
* Sharable. One writer and multiple readers may simultaneously access the same netCDF file.
* Archivable. Access to all earlier forms of netCDF data will be supported by current and future versions of the software.

%prep
%setup -q

%build
./configure --prefix=$RPM_BUILD_ROOT/usr/local
make

%install
make install

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*

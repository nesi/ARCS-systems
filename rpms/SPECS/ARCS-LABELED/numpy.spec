Summary:        numpy
Name:           numpy
Version:        1.1.0
Release:        1.arcs
License:        custom
Group:          Application/Libraries
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc python python-devel

%description
Library for OPeNDAP

%prep
%setup -q

%build
python setup.py bdist_dumb --plat-name linux-i386 --bdist-dir %{_tmppath}/%{name}-root -k

%install
rm -rf %{_tmppath}/%{name}-root/numpy-1.1.0.linux-i386.tar.gz

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/lib/python2.4/site-packages/*
/usr/bin/f2py

%changelog
* Thu Jun 05 2008 Florian Goessmann <florian@ivec.org>
- initial release

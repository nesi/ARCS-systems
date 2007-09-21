%define distname psqlodbc
%define _prefix /usr/srb

Summary:	SRB specific psqlodbc dependancy
Name:		srb-%{distname}
Version:	07.03.0200
Release:	1
License:	Custom
Group:		Applications/File
Source:		%{distname}-%{version}.tar.gz
Packager:	David Gwynne <dlg@itee.uq.edu.au>, Florian Goessmann <florian@ivec.org>
Buildroot:	%{_tmppath}/%{name}-root
BuildPreReq:	make gcc
%description
This is a specific version of psqlodbc with some packaging tweaks
so the Storage Resource Broker (SRB) can build against it.

SRB shouldn't be requiring a specific version of this software,
nor should it be using headers it doesnt install by default to
get a certain types.

%prep
%setup -q -n %{distname}-%{version}

%build
%configure
make

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
DESTDIR="$RPM_BUILD_ROOT" make install
mkdir -p $RPM_BUILD_ROOT%{_includedir}
for i in psqlodbc.so psqlodbc.la; do cp $RPM_BUILD_ROOT%{_libdir}/$i $RPM_BUILD_ROOT%{_libdir}/lib$i; done
cp -r $RPM_BUILD_DIR/%{distname}-%{version}/*.h $RPM_BUILD_ROOT%{_includedir}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
/usr/srb/*

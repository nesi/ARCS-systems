%define distname psqlodbc
%define _prefix /usr/srb

Summary:        SRB specific psqlodbc dependancy
Name:           srb-%{distname}
Version:        07.03.0200
Release:        1.arcs
License:        Custom
Group:          Applications/File
Source:         %{distname}-%{version}.tar.gz
Packager:       David Gwynne <dlg@itee.uq.edu.au>, Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc

%description
This is a specific version of psqlodbc with some packaging tweaks
so the Storage Resource Broker (SRB) can build against it.

SRB shouldn't be requiring a specific version of this software,
nor should it be using headers it doesn't install by default to
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
for i in psqlodbc.so psqlodbc.la; do cp $RPM_BUILD_ROOT%{_libdir}/$i $RPM_BUILD_ROOT%{_libdir}/lib$i.1.arcs; done
for i in psqlodbc.so psqlodbc.la; do mv $RPM_BUILD_ROOT%{_libdir}/$i $RPM_BUILD_ROOT%{_libdir}/$i.1.arcs; done
cp -r $RPM_BUILD_DIR/%{distname}-%{version}/*.h $RPM_BUILD_ROOT%{_includedir}

%post
ln -s %{_prefix}/lib/psqlodbc.so.1.arcs %{_prefix}/lib/psqlodbc.so
ln -s %{_prefix}/lib/libpsqlodbc.so.1.arcs %{_prefix}/lib/libpsqlodbc.so
ln -s %{_prefix}/lib/psqlodbc.la.1.arcs %{_prefix}/lib/psqlodbc.la
ln -s %{_prefix}/lib/libpsqlodbc.la.1.arcs %{_prefix}/lib/libpsqlodbc.la

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
/usr/srb/*

%changelog
* Mon Feb 11 2008 Florian Goessmann <florian@ivec.org>
- added changelog
- now depends on the SRB enabled package of gridFTP
- fixed ldconfig symlink error

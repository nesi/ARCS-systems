Summary:        eventlog
Name:           eventlog
Version:        0.2.7
Release:        1.arcs
License:        BSD
Group:          System/Library
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc

%description
The EventLog library aims to be a replacement of the simple syslog() API
provided on UNIX systems. The major difference between EventLog and syslog
is that EventLog tries to add structure to messages.

Where you had a simple non-structrured string in syslog() you have a
combination of description and tag/value pairs.

EventLog provides an interface to build, format and output an event record.
The exact format and output method can be customized by the administrator
via a configuration file.

%prep
%setup -q

%build
./configure --prefix=/usr
make

%install
make install

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/*

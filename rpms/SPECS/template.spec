Summary: A template for building other rpms
Name: template
Version: 0.1
Release: 0
License: ARCS
Group: Applications/Internet
# Source file is included in the SRPM and generally extracted into the buildroot via the setup macro
Source: template.tar.gz
Requires: /bin/sh, rpm
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-buildroot
%description
This is an example rpm which isnt expected to be installed

%prep
# Prep for build

%build
# Build the source
# %_sourcedir # refers to the source dir usually redhat/SOURCE
make

%install
# Install the binary
make install

%clean
# Remove all the data in the build root
rm -rf $RPM_BUILD_ROOT

%files
# Change the attributes on an erxecutable file
# %attr(0755,-,-) /usr/local/sbin/vdt-install-helper
# Doc file declariation
# %doc *.txt README

%changelog
* Fri Nov 09 2007 Russell Sim
- Created Initial Template


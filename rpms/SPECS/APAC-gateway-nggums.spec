%define source http://www.grid.apac.edu.au/repository/svn/systems/gateway/scripts/vdt-templates/trunk/vdt-config.nggums

Summary: GUMS rpm to provide the basics for an APAC GUMS service
Name: APAC-gateway-nggums
Version: 1.0
Release: 1
Copyright: APAC
Source: %{source}
Group: Applications/Internet
Requires: APAC-gateway-gridpulse, APAC-pacman, APAC-gateway-host-certificates, APAC-gateway-vdt-helper
BuildArch: noarch
BuildRoot: /tmp/%{name}-buildroot

%description
This is a meta RPM that pulls in the dependencies for basic nggums functionality

%prep
wget %{source} -O %_sourcedir/vdt-config.nggums 2> /dev/null

%install
mkdir -p $RPM_BUILD_ROOT/usr/local/etc
cp %_sourcedir/vdt-config.nggums $RPM_BUILD_ROOT/usr/local/etc

%files
/usr/local/etc/vdt-config.nggums

%clean
rm -rf $RPM_BUILD_ROOT

%changelog


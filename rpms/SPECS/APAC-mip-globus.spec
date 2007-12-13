%define PREFIX /usr/local

Summary: Globus configuration for the Modular Information Provider for APAC Grid usage
Name: APAC-mip-globus
version: 0.1
release: 2
License: GridAustralia
Group: Applications/Internet
Requires: APAC-mip, APAC-mip-module-py
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Globus configuration for the Modular Information Provider for GridAustralia

#%prep
#%setup -q -n globus_mip_config

%install
rm -rf $RPM_BUILD_ROOT
cd %{_sourcedir}/infosystems/globus/MIP
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/config/globus
cp -a * $RPM_BUILD_ROOT%{PREFIX}/mip/config/globus

%clean
rm -rf $RPM_BUILD_ROOT

%post
cd %{PREFIX}/mip
[ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
./config/globus/mip-globus-config -l /opt/vdt/globus install

%preun
cd %{PREFIX}/mip
[ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
./config/globus/mip-globus-config -l /opt/vdt/globus uninstall

%files
%defattr(-,root,root)
%{PREFIX}/mip/config/globus



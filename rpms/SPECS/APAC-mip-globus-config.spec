%define PREFIX /usr/local
%define DEP APAC-mip
%define package_name mip-globus-config

Summary: Globus configuration for the Modular Information Provider for APAC Grid usage
Name: APAC-%{package_name}
version: 0.1
release: 1
License: APAC?
Group: Applications/Internet
Source: globus_mip_config.tgz
Requires: %{DEP}
BuildArch: noarch

%description
Globus configuration for the Modular Information Provider for APAC Grid usage

%prep
%setup -q -n globus_mip_config

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/config

cd ..
cp -a globus_mip_config $RPM_BUILD_ROOT%{PREFIX}/mip/config/globus


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/mip/config/globus



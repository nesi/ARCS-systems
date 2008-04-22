Summary:	apac_py MIP module configuration
Name:		APAC-mip-module-py-config
version:	0.1
release:	2
License:	GridAustralia
Source:		apac_py-config.tar.gz
Prefix:		/usr/local
Group:		Applications/Internet
Requires:	APAC-mip APAC-mip-module-py
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch

%description
apac_py MIP module configuration (aka Youzhen's apac_py MIP configuration script)

%prep
%setup -n apac_py-config


%install
rm -rf $RPM_BUILD_ROOT
rm Makefile
mkdir -p $RPM_BUILD_ROOT%{prefix}/mip/config/apac_py
cp -a * $RPM_BUILD_ROOT%{prefix}/mip/config/apac_py
echo "Remember to modify and run $MIP_LOCATION/config/apac_py/mip-config.pl script"

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{prefix}/mip/config/apac_py

%changelog
* Tue Apr 22 2008 Gerson Galang
- modified the example sapac mip-config
- modified the AccessProtocol.Type's default value to gsiftp (not gridftp)
* Thu Mar 13 2008 Gerson Galang
- initial release of this spec file

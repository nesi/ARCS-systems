Summary:	ARCS-specific build/update scripts for Grid Gateway machines
Name:		Gbuild
Version:	1.8
Release:	3
Source:		gbuild.tar.gz
License:	GPL
Group:		Grid/Deployment
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch
Prefix:		/usr/local
Requires: 	perl APAC-gateway-gridpulse

%description
Provides local scripts for use when building Grid machines at ARCS sites. See: http://www.grid.apac.edu.au/repository/trac/systems/


%prep
%setup -n gbuild


%install

# TODO: most of these scripts need to be run by root, so sbin/ is more appropriate!
mkdir -p $RPM_BUILD_ROOT%{prefix}/bin
# gridpulse is a requirement so this directory will exist!
#mkdir -p $RPM_BUILD_ROOT/usr/local/lib/gridpulse
install *.sh $RPM_BUILD_ROOT%{prefix}/bin/
install gums.config $RPM_BUILD_ROOT%{prefix}/bin/


%clean
rm -rf $RPM_BUILD_ROOT


%post
#if upgrade remove first
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi
echo %{name} >> $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse


%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi


%files
%defattr(-,root,root)
%{prefix}/bin/


%changelog
* Fri Jan 25 2008 Daniel Cox
- secure MDS is handled by mip-globus package
* Mon Jan 22 2008 Daniel Cox
- fix spec file using APAC-gateway-gridpulse.spec as an example
- change version to 1.8 indicating VDT1.8 build scripts
- require newly named Gpulse so it can be removed from build scripts
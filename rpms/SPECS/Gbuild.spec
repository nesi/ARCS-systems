Summary:	ARCS-specific build/update scripts for Grid Gateway machines
Name:		Gbuild
Version:	1.8
Release:	1
License:	GPL
Group:		Grid/Deployment
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch
Prefix:		/usr/local
Requires: 	perl Gpulse

%description
Provides local scripts for use when building Grid machines at ARCS sites. See: http://www.grid.apac.edu.au/repository/trac/systems/

%prep

%install
cd ../SOURCES/scripts/gbuild
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/bin
mkdir -p $RPM_BUILD_ROOT/usr/local/lib/gridpulse

cp -p * $RPM_BUILD_ROOT/usr/local/bin

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
/usr/local/bin/
/usr/local/lib/


%changelog
* Mon Jan 21 2008 Daniel Cox
- fix spec file using APAC-gateway-gridpulse.spec as an example
- change version to 1.8 indicating VDT1.8 build scripts
- require Gpulse so it can be removed from build scripts
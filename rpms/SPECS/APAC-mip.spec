%define PKG_NAME mip

Summary:	The MIP modified for GridAustralia
Name:		APAC-mip
Version:	0.2.7
Release:	4
Source:		mip.tar.gz
# TODO: what was original MIP license? What are we allowed to specify it as?
License:	Apache
Group:		Applications/Internet
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch: 	noarch
Prefix:		/usr/local
Requires: 	perl
Provides: 	perl(lib::functions), perl(lib::producers), perl(lib::utilityfunctions), perl(lib::installer)

%description
The MIP (Modular Information Provider) modified for GridAustralia usage.


%prep
%setup -n mip


%install
rm -rf $RPM_BUILD_ROOT
rm Makefile
mkdir -p $RPM_BUILD_ROOT%{prefix}/%{PKG_NAME}
cp -a * $RPM_BUILD_ROOT%{prefix}/%{PKG_NAME}


%clean
rm -rf $RPM_BUILD_ROOT


%post
#if upgrade remove first
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi
echo %{name} >> $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse

cd $RPM_INSTALL_PREFIX0/%{PKG_NAME}
./install_mip


%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi


%files
%defattr(-,root,root)
%config %{prefix}/%{PKG_NAME}/config
%{prefix}/%{PKG_NAME}/INSTALL
%{prefix}/%{PKG_NAME}/README
%{prefix}/%{PKG_NAME}/install_mip
%{prefix}/%{PKG_NAME}/mip
%{prefix}/%{PKG_NAME}/*.pl
%{prefix}/%{PKG_NAME}/lib
%{prefix}/%{PKG_NAME}/modules


%changelog
* Fri Jan 25 2008 Daniel Cox
- include in gridpulse checks
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems director
y
- modified to fix the issue with the rpm not being relocatable (rel 3)
* Thu Dec 06 2007 Gerson Galang
- new glue spec file for the GridAustralia patched mip-0.2.7 (rel 2)

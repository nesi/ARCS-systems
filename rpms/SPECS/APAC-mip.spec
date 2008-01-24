%define PKG_NAME mip

Summary:	The Modular Information Provider modified for GridAustralia
Name:		APAC-mip
Version:	0.2.7
Release:	3
Source:		mip.tar.gz
License:	Apache
Group:		Applications/Internet
BuildRoot:	%{_tmppath}/%{name}-buildroot
Prefix:		/usr/local
Requires: 	perl
Provides: 	perl(lib::functions), perl(lib::producers), perl(lib::utilityfunctions), perl(lib::installer)
BuildArch: 	noarch

%description
The Modular Information Provider modified for GridAustralia usage

%prep
%setup -n mip

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{prefix}/%{PKG_NAME}
cp -a * $RPM_BUILD_ROOT%{prefix}/%{PKG_NAME}


%post
cd $RPM_INSTALL_PREFIX0/%{PKG_NAME}
./install_mip

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{prefix}/%{PKG_NAME}

%config %{prefix}/%{PKG_NAME}/config

%changelog
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems director
y
- modified to fix the issue with the rpm not being relocatable (rel 3)
* Thu Dec 06 2007 Gerson Galang
- new glue spec file for the GridAustralia patched mip-0.2.7 (rel 2)

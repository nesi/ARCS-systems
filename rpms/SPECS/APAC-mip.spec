%define PREFIX /usr/local
%define PKG_NAME mip
%define PKG_LOCATION infosystems/MIP/source

Summary: The Modular Information Provider modified for GridAustralia
Name: APAC-mip
Version: 0.2.7
Release: 2
License: Apache
Group: Applications/Internet
BuildRoot: /tmp/%{name}
Requires: perl
Provides: perl(lib::functions), perl(lib::producers), perl(lib::utilityfunctions), perl(lib::installer)
BuildArch: noarch

%description
The Modular Information Provider modified for GridAustralia usage

#%prep
#tar cfz %{PKG_NAME}-%{version}.tgz %{_sourcedir}/%{PKG_LOCATION}
#tar mxfz %{PKG_NAME}-%{version}.tgz

%install
rm -rf $RPM_BUILD_ROOT
cd %{_sourcedir}/%{PKG_LOCATION}
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{PKG_NAME}
cp -a * $RPM_BUILD_ROOT%{PREFIX}/%{PKG_NAME}
cd $RPM_BUILD_ROOT%{PREFIX}/%{PKG_NAME}
find ./ -name .svn -type d | xargs rm -rf

%post
cd %{PREFIX}/%{PKG_NAME}
./install_mip

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/%{PKG_NAME}

%config %{PREFIX}/%{PKG_NAME}/config

%changelog
* Thu Dec 06 2007 Gerson Galang
- new glue spec file for the GridAustralia patched mip-0.2.7 (rel 2)

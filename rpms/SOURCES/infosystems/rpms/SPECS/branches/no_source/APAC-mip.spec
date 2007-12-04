%define PREFIX /usr/local
%define package_name mip
%define major_version 0.2
%define minor_version 7

Summary: The Modular Information Provider modified for APAC Grid usage
Name: APAC-mip
version: %{major_version}.%{minor_version}
release: 1
License: apache
Group: Applications/Internet
Source: %{package_name}-%{version}.tar.gz
Patch: %{package_name}-%{version}.patch
Requires: perl APAC-lxml
Provides: perl(lib::functions), perl(lib::producers), perl(lib::utilityfunctions), perl(lib::installer)
BuildArch: noarch

%description
The Modular Information Provider modified for APAC Grid usage

%prep
%setup -q -n %{package_name}-%{version}
%patch -p0

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}

cp -a . $RPM_BUILD_ROOT%{PREFIX}/%{package_name}

%post
cd %{PREFIX}/%{package_name}
./install_mip

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/%{package_name}



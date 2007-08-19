%define package_name pacman
%define PREFIX /usr/local

Summary: Pacman - the package manager
Name: APAC-%{package_name}
Version: 3.19.1
Release: 1
Copyright: Saul Youssef
Group: Applications/Internet
Source: %{package_name}-%{version}.tar.gz
Requires: python
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs pacman - see http://physics.bu.edu/~youssef/pacman/

%prep
%setup -q -n %{package_name}-%{version}

%install
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
cp -a . $RPM_BUILD_ROOT%{PREFIX}/%{package_name}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/%{package_name}

%changelog
* Thu Nov 16 2006 Andrew Sharpe
- changed from pacman to APAC-pacman


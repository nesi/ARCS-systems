%define PREFIX /usr/local
%define PKG_LOCATION infosystems/schema

Summary: The APAC glue schema extensions
Name: APAC-glue-schema
Version: 0.1
Release: 3
License: APAC
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs the GLUE1.2 XML schema and GridAustralia GLUE1.2 XML schema extension

#%prep
#tar cfz %{name}-%{version}.tgz %{_sourcedir}/%{PKG_LOCATION}
#tar mxfz %{name}-%{version}.tgz

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/share
cd %{_sourcedir}/%{PKG_LOCATION}
cp -a * $RPM_BUILD_ROOT%{PREFIX}/share

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,-,-)
%{PREFIX}/share

%changelog
* Thu Dec 06 2007 Gerson Galang
- used infosystems/schema as the xsd files location (rel 3)


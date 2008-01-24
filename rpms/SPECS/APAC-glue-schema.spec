%define PKG_LOCATION infosystems/schema

Summary:	The APAC glue schema extensions
Name:		APAC-glue-schema
Version:	0.1
Release:	4
License:	APAC
Prefix:		/usr/local
Source:		glue-schema.tar.gz
Group:		Applications/Internet
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch

%description
Installs the GLUE1.2 XML schema and GridAustralia GLUE1.2 XML schema extension

%prep
%setup -n glue-schema

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{prefix}/share
rm Makefile
cp -a * $RPM_BUILD_ROOT%{prefix}/share

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%{prefix}/share

%changelog
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems director
y
- modified to fix the issue with the rpm not being relocatable (rel 4)
* Thu Dec 06 2007 Gerson Galang
- used infosystems/schema as the xsd files location (rel 3)


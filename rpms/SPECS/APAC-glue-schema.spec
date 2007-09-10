%define PREFIX /usr/local

Summary: The APAC glue schema extensions
Name: APAC-glue-schema
Version: 0.1
Release: 1
License: APAC
Group: Applications/Internet
Source: APACGLUESchema12R1.xsd
Source1: GLUESchema12R2.xsd
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs the APAC globus configuration files into /etc/grid-security/certificates to allow easy certificate request generation.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/share
cp %{SOURCE0} %{SOURCE1} $RPM_BUILD_ROOT%{PREFIX}/share

%clean
rm -rf $RPM_BUILD_ROOT

#%post
#mkdir -p %{PREFIX}/lib/gridpulse
#echo %{name} >> %{PREFIX}/lib/gridpulse/system_packages.pulse

#%postun
#perl -ni -e "print unless /^%{name}/;" %{PREFIX}/lib/gridpulse/system_packages.pulse


%files
%defattr(755,root,root)
%{PREFIX}/share



%define PREFIX /usr/local

Summary: The APAC globus default CA certificate configuration
Name: APAC-CA-config
Version: 0.1
Release: 1
Copyright: GPL
Group: Applications/Internet
Source: %{name}-%{version}-%{release}.tgz
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
Installs the APAC globus configuration files into /etc/grid-security/certificates to allow easy certificate request generation.

%prep
%setup

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/grid-security/certificates
cp -a . $RPM_BUILD_ROOT/etc/grid-security/certificates

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p %{PREFIX}/lib/gridpulse
echo %{name} >> %{PREFIX}/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^%{name}/;" %{PREFIX}/lib/gridpulse/system_packages.pulse


%files
%defattr(755,root,root)
/etc/grid-security/certificates/*

%changelog


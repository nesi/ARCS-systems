%define PREFIX /usr/local
%define SVN_URL http://auriga.qut.edu.au/svn/apac/gateway/schema/trunk
%define REVISION 290
%define PKG_NAME schema


Summary: The APAC glue schema extensions
Name: APAC-glue-schema
Version: 0.1
Release: 2
Copyright: APAC
Group: Applications/Internet
BuildArch: noarch

%description
Installs the APAC glue xml schemas

The source is available from SVN at %{SVN_URL}, revision %{REVISION}

%prep
# download the source
wget "http://ng0.hpc.jcu.edu.au/cgi-bin/svn_tarball?repo=%{SVN_URL}&rev=%{REVISION}&dir=%{PKG_NAME}" -O %{PKG_NAME}.tgz
tar mzxf %{PKG_NAME}.tgz


%install
rm -rf $RPM_BUILD_ROOT
cd %{PKG_NAME}
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/share
cp -a * $RPM_BUILD_ROOT%{PREFIX}/share

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



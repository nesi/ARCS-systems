%define PREFIX /usr/local
%define SVN_URL http://auriga.qut.edu.au/svn/apac/gateway/globus/MIP
%define REVISION 285
%define PKG_NAME mip_globus
%define DEP APAC-mip


Summary: Globus configuration for the Modular Information Provider for APAC Grid usage
Name: APAC-mip-globus
version: 0.1
release: 1
License: APAC
Group: Applications/Internet
Requires: %{DEP}
BuildArch: noarch

%description
Globus configuration for the Modular Information Provider (MIP) for APAC Grid usage

The source is available from SVN at %{SVN_URL}, revision %{REVISION}

%prep
# download the source
wget "http://ng0.hpc.jcu.edu.au/cgi-bin/svn_tarball?repo=%{SVN_URL}&rev=%{REVISION}&dir=%{PKG_NAME}" -O %{PKG_NAME}.tgz
tar mzxf %{PKG_NAME}.tgz


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/config

cp -a %{PKG_NAME} $RPM_BUILD_ROOT%{PREFIX}/mip/config/globus


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/mip/config/globus



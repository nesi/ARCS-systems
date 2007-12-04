%define PREFIX /usr/local
%define SVN_URL http://auriga.qut.edu.au/svn/apac/gateway/MIP/modules/apac_py/trunk/
%define REVISION 358
%define PKG_NAME apac_py
%define DEP APAC-mip


Summary: The Modular Information Provider modified for APAC Grid usage
Name: APAC-mip-module-py
version: 1.0.%{REVISION}
#version: %{REVISION}
release: 1
License: APAC?
Group: Applications/Internet
#Source: %{PKG_NAME}.tgz
Requires: %{DEP}, APAC-glue-schema
BuildArch: noarch

%description
The Modular Information Provider modified for APAC Grid usage

The source is available from SVN at %{SVN_URL}, revision %{REVISION}

%prep
wget "http://ng0.hpc.jcu.edu.au/cgi-bin/svn_tarball?repo=%{SVN_URL}&rev=%{REVISION}&dir=%{PKG_NAME}" -O %{PKG_NAME}.tgz
tar mzxf %{PKG_NAME}.tgz


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/modules

cp -a %{PKG_NAME} $RPM_BUILD_ROOT%{PREFIX}/mip/modules

%post
BASE=%{PREFIX}/mip
cd $BASE

perl -pi -e "s/^(pkgs.*)$/#\1\npkgs       => ['default',],/" config/source.pl

if [ ! -e "modules/default" ]; then
	ln -sf %{PKG_NAME} modules/default
fi
if [ ! -f "config/apac_config.py" ]; then
	cp modules/default/example_config.py config/apac_config.py
	perl -pi -e "s/apac_py/default/g" config/apac_config.py
fi
if [ ! -f "config/default_sub1_SIP.ini" ]; then
	cp modules/apac_py/exampleSoftwareInfoProvider.ini config/default_sub1_SIP.ini
	perl -pi -e "s|softwareInfoData/softwareParser.log|/dev/null|" config/default_sub1_SIP.ini
fi
if [ ! -f "config/default.pl" ]; then
	cat <<-EOF > config/default.pl
		clusterlist => ['default'],
		uids =>  {      
		   Site => [ "TEST", ],
		#   Cluster => [ "cluster1", ],
		#   ComputingElement => [ "compute1", ],
		#   SubCluster => [ "sub1", ],
		#   StorageElement => [ "storage1", ],
		}
	EOF
fi



%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/mip/modules/%{PKG_NAME}



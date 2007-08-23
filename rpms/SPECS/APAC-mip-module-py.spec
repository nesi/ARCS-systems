%define PREFIX /usr/local
%define DEP APAC-mip
%define package_name mip-module-py
#%define major_version 0.2
#%define minor_version 7

# how to get the source:
#   svn co http://auriga.qut.edu.au/svn/apac/gateway/MIP/modules/apac_py/trunk APAC-mip-module-py
#   tar zcf APAC-mip-module-py-0.1.tar.gz APAC-mip-module-py


Summary: The Modular Information Provider modified for APAC Grid usage
Name: APAC-%{package_name}
version: 0.1
release: 1
License: APAC?
Group: Applications/Internet
Source: APAC-%{package_name}-%{version}.tar.gz
BuildRoot: /tmp/%{name}-buildroot
Requires: %{DEP}, APAC-glue-schema
BuildArch: noarch

%description
The Modular Information Provider modified for APAC Grid usage

%prep
%setup -q -n %{name}

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/modules

find ./ -name .svn -type d | xargs rm -rf
cd ..
cp -a %{name} $RPM_BUILD_ROOT%{PREFIX}/mip/modules/apac_py

%post
BASE=%{PREFIX}/mip
cd $BASE

perl -pi -e "s/^(pkgs.*)$/#\1\npkgs       => ['default',],/" config/source.pl

if [ ! -e "modules/default" ]; then
	ln -sf apac_py modules/default
fi
if [ ! -f "config/apac_config.py" ]; then
	cp modules/default/example_config.py config/apac_config.py
	perl -pi -e "s/apac_py/default/g" config/apac_config.py
fi
if [ ! -f "config/softwareInfoProvider.ini" ]; then
	cp modules/apac_py/exampleSoftwareInfoProvider.ini config/softwareInfoProvider.ini
fi
if [ ! -f "config/default.pl" ]; then
	cat <<-EOF > config/default.pl
		clusterlist => ['default'],
		uids =>  {      
		   Site => [ "TEST", ],
		   SubCluster => [ "sub1", ],
		   Cluster => [ "cluster1", ],
		   ComputingElement => [ "compute1", ],
		   StorageElement => [ "storage1", ],
		}
	EOF
fi



%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{PREFIX}/mip/modules/apac_py



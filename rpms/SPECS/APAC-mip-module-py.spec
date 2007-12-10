%define PREFIX /usr/local
%define PKG_NAME apac_py
%define REVISION 381

Summary: The GridAustralia Modular Information Provider module
Name: APAC-mip-module-py
Version: 1.0.%{REVISION}
Release: 1
License: ARCS
Group: Applications/Internet
Requires: APAC-mip, APAC-glue-schema, APAC-lxml
BuildRoot: /tmp/%{name}-buildroot
BuildArch: noarch

%description
The GridAustralia Modular Information Provider module

#%prep
#tar cfz %{PKG_NAME}-%{version}.tgz %{_sourcedir}/infosystems/MIP/modules
#tar mxfz %{PKG_NAME}-%{version}.tgz

%install
rm -rf $RPM_BUILD_ROOT
cd %{_sourcedir}/infosystems/MIP/modules
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/mip/modules
cp -a * $RPM_BUILD_ROOT%{PREFIX}/mip/modules
cd $RPM_BUILD_ROOT%{PREFIX}/mip
find ./ -name .svn -type d | xargs rm -rf

%post
cd %{PREFIX}/mip
if [ ! -e "modules/default" ]; then
        ln -sf apac_py modules/default
fi
if [ ! -f "config/apac_config.py" ]; then
        cp modules/default/example_config.py config/apac_config.py
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
%defattr(-,-,-)
%{PREFIX}/mip/modules/%{PKG_NAME}

%changelog
* Thu Dec 06 2007 Gerson Galang
- new glue spec file based on andrew sharpe's spec file


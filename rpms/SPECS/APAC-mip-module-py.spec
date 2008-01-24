%define PKG_NAME apac_py
%define REVISION 444

Summary:	The GridAustralia Modular Information Provider module
Name:		APAC-mip-module-py
Version:	1.0.%{REVISION}
Release:	4
License:	ARCS
Group:		Applications/Internet
Prefix:		/usr/local
Source:		apac_py.tar.gz
Requires:	APAC-mip, APAC-glue-schema, APAC-lxml
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch

%description
The GridAustralia Modular Information Provider module

%prep
%setup -n apac_py

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{prefix}/mip/modules/%{PKG_NAME}
cp -a * $RPM_BUILD_ROOT%{prefix}/mip/modules/%{PKG_NAME}

%post
cd $RPM_INSTALL_PREFIX0/mip
if [ ! -e "modules/default" ];
then
        ln -sf modules/apac_py modules/default
fi
if [ ! -f "config/apac_config.py" ];
then
        cp modules/default/example_config.py config/apac_config.py
else
        echo "Backing up old config/apac_config.py to config/apac_config.py.`date +%Y%m%d`."
        cp config/apac_config.py config/apac_config.py.`date +%Y%m%d`
        sed 's/\.protocols\[/\.access_protocols\[/' config/apac_config.py > config/apac_config.py.tmp
        mv config/apac_config.py.tmp config/apac_config.py
        sed "s/computeElement\.Status = 'Queueing'/computeElement\.Status = 'Production'/" config/apac_config.py > config/apac_config.py.tmp
        mv config/apac_config.py.tmp config/apac_config.py
        sed "s/accessProtocol\.Version = '1.0.0'/accessProtocol\.Version = '2.3'/" config/apac_config.py > config/apac_config.py.tmp
        mv config/apac_config.py.tmp config/apac_config.py
        echo "This version of the GridAus-mip module already supports publishing of SRM information."
        echo "%{prefix}/mip/modules/apac_py/example_config.py has examples of how to publish SRM information."
fi
if [ ! -f "config/softwareInfoProvider.ini" ];
then
        cp modules/apac_py/exampleSoftwareInfoProvider.ini config/softwareInfoProvider.ini
fi
if [ ! -f "config/default.pl" ];
then
cat <<-EOF > config/default.pl
  clusterlist => ['default'],
  uids =>  {
    Site => [ "TEST", ],
#    SubCluster => [ "sub1", ],
#    Cluster => [ "cluster1", ],
#    ComputingElement => [ "compute1", ],
#    StorageElement => [ "storage1", ],
  }
EOF
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{prefix}/mip/modules/%{PKG_NAME}

%config(noreplace) %{prefix}/mip/modules/%{PKG_NAME}/SubCluster/softwareInfoData

%changelog
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems directory
* Wed Jan 23 2008 Gerson Galang
- added Vlad's workaround to the max int32 limit issue with Available and UsedSpace attributes of the StorageElement
* Thu Dec 13 2007 Gerson Galang
- added softwareInfoData directory to the config list
* Thu Dec 06 2007 Gerson Galang
- new glue spec file based on andrew sharpe's spec file

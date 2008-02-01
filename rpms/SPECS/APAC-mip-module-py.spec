%define PKG_NAME apac_py
%define REVISION 444

Summary:	The GridAustralia MIP module
Name:		APAC-mip-module-py
Version:	1.0.%{REVISION}
Release:	6
Source:		apac_py.tar.gz
License:	GPL
Group:		Applications/Internet
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch
Prefix:		/usr/local
Requires:	APAC-mip, APAC-glue-schema, APAC-lxml

%description
The GridAustralia MIP (Modular Information Provider) module


%prep
%setup -n apac_py


%install
rm -rf $RPM_BUILD_ROOT
rm Makefile
mkdir -p $RPM_BUILD_ROOT%{prefix}/mip/modules/%{PKG_NAME}
cp -a * $RPM_BUILD_ROOT%{prefix}/mip/modules/%{PKG_NAME}


%clean
rm -rf $RPM_BUILD_ROOT


%post
#if upgrade remove first
if [ $1 -gt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi
echo %{name} >> $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse


cd $RPM_INSTALL_PREFIX0/mip
if [ ! -e "modules/default" ];
then
        ln -sf apac_py modules/default
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


%postun
# if its an uninstall
if [ $1 -lt 1 ]; then
	perl -ni -e "print unless /^%{name}/;" $RPM_INSTALL_PREFIX0/lib/gridpulse/system_packages.pulse
fi


%files
%defattr(-,root,root)
%config(noreplace) %{prefix}/mip/modules/%{PKG_NAME}/SubCluster/softwareInfoData
%{prefix}/mip/modules/%{PKG_NAME}/Cluster
%{prefix}/mip/modules/%{PKG_NAME}/ComputingElement
%{prefix}/mip/modules/%{PKG_NAME}/Site
%{prefix}/mip/modules/%{PKG_NAME}/StorageElement
%{prefix}/mip/modules/%{PKG_NAME}/SubCluster/subcluster.py
%{prefix}/mip/modules/%{PKG_NAME}/SubCluster/softwareInfoProvider.py
%{prefix}/mip/modules/%{PKG_NAME}/*.py
%{prefix}/mip/modules/%{PKG_NAME}/exampleSoftwareInfoProvider.ini

%changelog
* Fri Feb 1 2008 Gerson Galang
- fix post install script to work for a fresh install
* Fri Jan 25 2008 Daniel Cox
- include in gridpulse checks
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems directory
* Wed Jan 23 2008 Gerson Galang
- added Vlad's workaround to the max int32 limit issue with Available and UsedSpace attributes of the StorageElement
* Thu Dec 13 2007 Gerson Galang
- added softwareInfoData directory to the config list
* Thu Dec 06 2007 Gerson Galang
- new glue spec file based on andrew sharpe's spec file

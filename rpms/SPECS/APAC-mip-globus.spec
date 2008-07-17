Summary:	Globus configuration for the Modular Information Provider for APAC Grid usage
Name:		APAC-mip-globus
version:	0.1
release:	10
License:	GridAustralia
Source:		globus-mip-config.tar.gz
Prefix:		/usr/local
Group:		Applications/Internet
Requires:	APAC-gateway-gridpulse APAC-mip APAC-mip-module-py
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch:	noarch

%description
Globus configuration for the Modular Information Provider for GridAustralia


%prep
%setup -n globus-mip-config


%install
rm -rf $RPM_BUILD_ROOT
rm Makefile
mkdir -p $RPM_BUILD_ROOT%{prefix}/mip/config/globus
cp -a * $RPM_BUILD_ROOT%{prefix}/mip/config/globus


%clean
rm -rf $RPM_BUILD_ROOT


%post
cd $RPM_INSTALL_PREFIX0/mip
if [ $1 -gt 1 ]; then
  [ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
  ./config/globus/mip-globus-config -l /opt/vdt/globus uninstall
fi
[ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
./config/globus/mip-globus-config -l /opt/vdt/globus install


%postun
# only do this when uninstalling
if [ $1 -lt 1 ]; then
  cd $RPM_INSTALL_PREFIX0/mip
  [ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
  ./config/globus/mip-globus-config -l /opt/vdt/globus uninstall
fi


%files
%defattr(-,root,root)
%{prefix}/mip/config/globus

%changelog
* Thu Jul 17 2008 Gerson Galang (rel 10)
- fixed post and postun scriptlets
* Wed Jul 2 2008 Gerson Galang
- rel 8 updated domain names of mds0 and mds1 to arcs.org.au of hierarchy.xml
* Tue May 20 2008 Gerson Galang
- rel 7 applied vlad's suggestion https://projects.arcs.org.au/trac/systems/ticket/16
* Mon Feb 18 2008 Gerson Galang
- modified the two upstream index services in hierarchy.xml
* Thu Jan 24 2008 Gerson Galang
- modified to reflect changes in the directory structure of all the packages inside the infosystems director
y
- modified to fix the issue with the rpm not being relocatable (rel 3)


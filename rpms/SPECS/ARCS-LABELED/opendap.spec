Summary:        OPeNDAP  Meta Package
Name:           OPeNDAP
Version:        0
Release:        3.arcs
License:        custom
Group:          Applications/Internet
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
Requires:       libdap == 3.8.0 bes HDF netcdf hdf4_handler netcdf_handler

%description
OPeNDAP Meta Package that installs all OPeNDAP realted RPMs provided by ARCS. It also provides basic configuration for BES in order to include all the provided handlers.

%prep

%build

%install

%post
mv /usr/local/etc/bes/bes.conf /usr/local/etc/bes/bes.conf.bak
sed 's|/var/tmp/bes-root||g' /usr/local/etc/bes/bes.conf.bak > /usr/local/etc/bes/bes.conf
rm /usr/local/etc/bes/bes.conf.bak

mv /usr/local/etc/bes/bes.conf /usr/local/etc/bes/bes.conf.bak
sed '/^BES.modules=/ s/=[a-z,0-9]*/=dap,cmd,www,nc,h4,ascii/g' /usr/local/etc/bes/bes.conf.bak > /usr/local/etc/bes/bes.conf
rm /usr/local/etc/bes/bes.conf.bak

mv /usr/local/etc/bes/bes.conf /usr/local/etc/bes/bes.conf.bak
sed '/^BES.module\.[a-z]*/ s|[a-z/=._A-Z0-9]*||g' /usr/local/etc/bes/bes.conf.bak > /usr/local/etc/bes/bes.conf
rm /usr/local/etc/bes/bes.conf.bak

mv /usr/local/etc/bes/bes.conf /usr/local/etc/bes/bes.conf.bak
sed '/^BES.modules=/ s|$|\nBES.module.dap=/usr/local/lib/bes/libdap_module.so\nBES.module.cmd=/usr/local/lib/bes/libdap_cmd_module.so\nBES.module.www=/usr/local/lib/bes/libwww_module.so\nBES.module.nc=/usr/local/lib/bes/libnc_module.so\nBES.module.h4=/usr/local/lib/bes/libhdf4_module.so\nBES.module.ascii=/usr/local/lib/bes/libascii_module.so|g' /usr/local/etc/bes/bes.conf.bak > /usr/local/etc/bes/bes.conf
rm /usr/local/etc/bes/bes.conf.bak

%clean
rm -rf $RPM_BUILD_ROOT

%files

%changelog
* Tue Apr 22 2008 Florian Goessmann <florian@ivec.org>
- added ascii handler to modules
* Tue Apr 1 2008 Florian Goessmann <florian@ivec.org>
- fixed bug in post install

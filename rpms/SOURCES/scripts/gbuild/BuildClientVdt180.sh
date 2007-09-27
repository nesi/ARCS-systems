#!/bin/sh
# BuildClientVdt161.sh	APAC Globus Client build from VDT 1.6.x cache.
#			Installs Globus-Base-Data-Server with APAC-specific
#			additions on a minimal CentOS 4.4 or similar machine.
#			Graham Jenkins <graham@vpac.org> Jan 2007, Rev 20070512

#
# PATH, environment, id-check, hosts-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_ENABLE_GRIDFTP=y    \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_INSTALL_CERTS=r     \
VDTSETUP_EDG_CRL_UPDATE=y     VDTSETUP_ENABLE_WS_CONTAINER=n
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's
echo "==> Installing: Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install Gclient vim-minimal dhclient openssh-clients openssl097a  \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap libXp   \
            tcsh openssh-server sudo lsof slocate bind-utils telnet   \
            gcc vixie-cron anacron crontabs diffutils xinetd tmpwatch \
            sysklogd logrotate compat-libstdc++-33 compat-libcom_err  \
            man gcc-c++ $Extras

#
# Pacman, port-range adjustment, VDT-Setup adjustment
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  echo "export GLOBUS_TCP_PORT_RANGE=$TcpRange"    >/opt/vdt/post-setup/APAC01.sh
  echo "export MYPROXY_SERVER=myproxy.apac.edu.au">>/opt/vdt/post-setup/APAC01.sh
  chmod a+xr /opt/vdt/post-setup/APAC01.sh
  echo "==> Created: /opt/vdt/post-setup/APAC01.sh"
fi
PACMAN=pacman-3.20
# TODO: download from APAC repository instead?
#  http://www.grid.apac.edu.au/repository/trac/systems/browser/gateway/rpms/SOURCES
if [ ! -d $PACMAN ]; then
  echo "==> Installing: Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/$PACMAN.tar.gz &&
  tar xzf $PACMAN.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd $PACMAN && source setup.sh && cd ..

Platform=linux-rhel-4
if grep Zod /etc/redhat-release >/dev/null 2>&1 ; then
  Platform=linux-fedora-4	# Kludge so it works for Fedora-Core 6 :(
  [ -e /lib/libssl.so.5    ] || ln -s /lib/libssl.so.6    /lib/libssl.so.5
  [ -e /lib/libcrypto.so.5 ] || ln -s /lib/libcrypto.so.6 /lib/libcrypto.so.5
fi

#
# VDT Components .. Globus-Base-SDK included to enable MyProxy rebuild etc. 
PLATFORM="-pretend-platform linux-rhel-4"
VDTVER=1.8.0
VDTMIRROR=http://www.grid.apac.edu.au/repository/mirror/vdt-$VDTVER.mirror
VDTMIRROR=http://www.grid.apac.edu.au/repository/mirror/vdt/vdt_180_cache
for Component in Globus-WS-Client Globus-Base-RM-Client GSIOpenSSH           \
                 Globus-Base-Data-Server VOMS-Client MyProxy Globus-Base-SDK \
                 Globus-Base-Info-Essentials Globus-Base-WSMDS-Server; do
  echo "==> Checking/Installing: $Component"
  pacman $PLATFORM $ProxyString \
    -get $VDTMIRROR:$Component || echo "==> Failed!"
done

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman $PLATFORM $ProxyString -update CA-Certificates

#
# Install startup scripts etc.
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
. /etc/profile ; vdt-control --force --on && echo "==> Installed: startup scripts"

#
# Wrapup
echo "==> Re-loading: xinetd"
chkconfig --add xinetd; service xinetd start; service xinetd reload
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
[ ! -f /etc/cron.hourly/01-gridmap-local.cron ]                                && 
  cp /usr/local/src/01-gridmap-local.cron /etc/cron.hourly                     && 
  echo "==> Please edit: /etc/cron.hourly/01-gridmap-local.cron for your site"
exit 0

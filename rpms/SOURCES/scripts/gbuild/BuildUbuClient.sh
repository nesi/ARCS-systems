#!/bin/bash
# BuildUbuClient.sh	APAC Globus Client build from VDT 1.6.x cache.
#			Installs Globus-Base-Data-Server with APAC-specific
#			additions on a Ubuntu 7.04 (Fiesty) machine.
#			Graham Jenkins <graham@vpac.org> May 2007, Rev 20070524

#
# PATH, environment, id-check, rpm-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_ENABLE_GRIDFTP=y    \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_INSTALL_CERTS=r     \
VDTSETUP_EDG_CRL_UPDATE=y     VDTSETUP_ENABLE_WS_CONTAINER=n
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2

#
# Essential packages
apt-get install xinetd rpm g++
! rpm -q Gclient >/dev/null 2>&1 && \
  echo "==> You need to acquire and install the Gbuild RPM package"         && exit 2 

#
# Pacman, port-range adjustment, VDT-Setup adjustment
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  echo "export GLOBUS_TCP_PORT_RANGE=$TcpRange"      >/opt/vdt/post-setup/APAC01.sh
  echo "export MYPROXY_SERVER=myproxy.apac.edu.au"  >>/opt/vdt/post-setup/APAC01.sh
  echo "export GRID_SECURITY_DIR=/etc/grid-security">>/opt/vdt/post-setup/APAC01.sh
  chmod a+xr /opt/vdt/post-setup/APAC01.sh
  echo "==> Created: /opt/vdt/post-setup/APAC01.sh"
fi
if [ ! -d pacman-3.19 ]; then
  echo "==> Installing: Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/pacman-3.19.tar.gz &&
  tar xzf pacman-3.19.tar.gz || echo "==> Failed!"
fi
cd pacman-3.19 && . ./setup.sh && cd ..

#
# VDT Components .. Globus-Base-SDK included to enable MyProxy rebuild etc. 
Platform=linux-debian-3.1
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"
for Component in Globus-WS-Client Globus-Base-RM-Client GSIOpenSSH           \
                 Globus-Base-Data-Server VOMS-Client MyProxy Globus-Base-SDK \
                 Globus-Base-Info-Essentials Globus-Base-WSMDS-Server; do
  echo "==> Checking/Installing: $Component"
  pacman -pretend-platform $Platform $ProxyString \
    -get http://www.grid.apac.edu.au/repository/mirror/vdt-1.6.1.mirror:$Component || echo "==> Failed!"
done

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman   -pretend-platform $Platform $ProxyString -update CA-Certificates

#
# Install startup scripts etc.
grep /opt/vdt/ /etc/profile >/dev/null ||
  sed --in-place=.ORI -e '/BASH/i\  . /opt/vdt/setup.sh' /etc/profile
. /opt/vdt/setup.sh && vdt-control --force --on && echo "==> Installed: startup scripts"

#
# Use 'bash' instead of 'sh' so that 'source' statement are recognised
grep /bin/bash /opt/vdt/vdt/services/vdt-run-gsiftp.sh >/dev/null ||
  sed --in-place=.ORI -e 's_/bin/sh_/bin/bash_' /opt/vdt/vdt/services/vdt-run-gsiftp.sh

#
# Wrapup
pkill -HUP xinetd
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
[ ! -f /etc/cron.hourly/01-gridmap-local.cron ]                                && 
  cp /usr/local/src/01-gridmap-local.cron /etc/cron.hourly                     && 
  echo "==> Please edit: /etc/cron.hourly/01-gridmap-local.cron for your site"
exit 0

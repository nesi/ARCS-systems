#!/bin/bash
# BuildCentosClient.sh	ARCS Globus Client build from VDT 1.8.x cache.
#                       Installs useful client software from VDT
#                       2007-09-19 S. McMahon, ANU
# 
# You should be able to install this as an ordinary user
#
# PATH, environment
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y      \
VDTSETUP_INSTALL_CERTS=l     \
VDTSETUP_EDG_CRL_UPDATE=y    VDTSETUP_CA_CERT_UPDATER=y

#
# Pacman, port-range adjustment, VDT-Setup adjustment
# currently assuming write access to /opt/vdt.  This should possibly be parameterised.
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  echo "export GLOBUS_TCP_PORT_RANGE=$TcpRange"      >/opt/vdt/post-setup/APAC01.sh
  echo "export MYPROXY_SERVER=myproxy.apac.edu.au"  >>/opt/vdt/post-setup/APAC01.sh
# the following doesn't fit with locally installed certificates.
#  echo "export GRID_SECURITY_DIR=/etc/grid-security">>/opt/vdt/post-setup/APAC01.sh
  chmod a+xr /opt/vdt/post-setup/APAC01.sh
  echo "==> Created: /opt/vdt/post-setup/APAC01.sh"
fi

PACMAN=pacman-3.20
# TODO: download from APAC repository instead?
#  http://www.grid.apac.edu.au/repository/trac/systems/browser/gateway/rpms/SOURCES
if [ ! -d $PACMAN ]; then
  echo "==> Installing Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/$PACMAN.tar.gz &&
  tar xzf $PACMAN.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd $PACMAN && source setup.sh && cd ..

# set up Pacman settings.
Platform="-pretend-platform linux-rhel-4"
VDTMIRROR=http://www.grid.apac.edu.au/repository/mirror/vdt/vdt_180_cache
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

# set up the cache as trusted
if [ ! -f trusted-caches ]; then
    echo $VDTMIRROR > trusted.caches
fi

#
# VDT Components .. 

for Component in Globus-Client Globus-WS-Client GSIOpenSSH MyProxy UberFTP VOMS-Client; do
  echo "==> Checking/Installing: $Component"
  pacman $Platform $ProxyString -get $VDTMIRROR:$Component || echo "==> Failed!"
done

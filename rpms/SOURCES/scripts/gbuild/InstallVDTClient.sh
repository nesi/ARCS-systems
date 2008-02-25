#!/bin/bash
# InstallVDTClient.sh	Installs useful client software from VDT
#                       09/11/2007 -- S. McMahon, ANU
# 
# Installation of VDT client components without root privileges.
#

# get the installation directory
[ -n "$VDT_LOCATION" ] || VDT_LOCATION=$PWD/vdt
until [ -w "$VDT_LOCATION" ]; do
    echo -n "Please specify the installation directory [$VDT_LOCATION]: "
    read ans
    if [ "$ans" != "" ]; then
	VDT_LOCATION=$ans
    fi
    echo using $VDT_LOCATION
    if [ ! -d $VDT_LOCATION ]; then
	echo creating $VDT_LOCATION
	mkdir -p $VDT_LOCATION
    fi
done

# setup environment for unattended installation
export VDTSETUP_AGREE_TO_LICENSES=y      \
VDTSETUP_INSTALL_CERTS=l     \
VDTSETUP_EDG_CRL_UPDATE=y    VDTSETUP_CA_CERT_UPDATER=y

#
# Pacman, port-range adjustment, VDT-Setup adjustment
mkdir -p $VDT_LOCATION/post-setup; cd $VDT_LOCATION
if [ ! -f $VDT_LOCATION/post-setup/APAC01.sh ] ; then
  until [ -n "$GLOBUS_TCP_PORT_RANGE" ]; do
    GLOBUS_TCP_PORT_RANGE="40000,41000"
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [ $GLOBUS_TCP_PORT_RANGE ]: " 
    read ans
    if [ "$ans" != "" ]; then
	TcpRange=$ans
    fi
    echo "$GLOBUS_TCP_PORT_RANGE" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  echo "export GLOBUS_TCP_PORT_RANGE=$GLOBUS_TCP_PORT_RANGE"      > $VDT_LOCATION/post-setup/APAC01.sh
  echo "export MYPROXY_SERVER=myproxy.apac.edu.au"  >> $VDT_LOCATION/post-setup/APAC01.sh
  chmod a+xr $VDT_LOCATION/post-setup/APAC01.sh
  echo "==> Created: $VDT_LOCATION/post-setup/APAC01.sh"
fi

PACMAN=pacman-3.20
# TODO: download from APAC repository instead?
#  http://www.grid.apac.edu.au/repository/trac/systems/browser/gateway/rpms/SOURCES
if [ ! -d $PACMAN ]; then
  echo "==> Installing Pacman!"
  which wget > /dev/null || ( echo "wget not in path!" && exit 1 )
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/$PACMAN.tar.gz &&
  tar xzf $PACMAN.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd $PACMAN && source setup.sh && cd ..

# set up Pacman settings.
VDTMIRROR=http://www.grid.apac.edu.au/repository/mirror/vdt/vdt_181_cache
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

# set up platform.  More special cases need to be added here.
# tested on Mac OS 10.4 (i386).
# tested on Centos 5. (i686) 09/11/2007 -- S. McMahon
Platform=""
if [ -f /etc/redhat-release ]; then
    Platform="-pretend-platform linux-rhel-4"
    if grep Zod /etc/redhat-release >/dev/null 2>&1 ; then
        # Kludge so it works for Fedora-Core 6 :(
	Platform="-pretend-platform linux-fedora-4"
	[ -e /lib/libssl.so.5    ] || ln -s /lib/libssl.so.6    /lib/libssl.so.5
	[ -e /lib/libcrypto.so.5 ] || ln -s /lib/libcrypto.so.6 /lib/libcrypto.so.5
    fi
fi

#
# VDT Components .. 

components="Globus-Client Globus-WS-Client MyProxy UberFTP VOMS-Client"
# At the moment GSIOpenSSH does not seem to work on Mac OS 10.5
if [ `uname -s` != "Darwin" ]; then
    components="$components GSIOpenSSH"
fi
for Component in $components; do
  echo "==> Checking/Installing: $Component"
  pacman $Platform $ProxyString -get $VDTMIRROR:$Component || echo "==> Failed!"
done

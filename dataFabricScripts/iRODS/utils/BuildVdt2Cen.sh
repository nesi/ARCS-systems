#!/bin/sh
# BuildVdt2Ubu.sh  GridFTP/MyProxy build from VDT 2.0.0 cache.
#                  Suitable for use on an CentOS 5.5 machine.
#                  Graham Jenkins <graham@vpac.org> Mar. 2011
# Ref: http://vdt.cs.wisc.edu/releases/2.0.0/installation_quick.html
 
# PATH, installation directory
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin            \
       VDTSETUP_AGREE_TO_LICENSES=y
mkdir -p /opt/vdt; cd /opt/vdt || exit 1

# Pre-requisites
yum install vim-enhanced ntp telnet gcc vixie-cron anacron crontabs \
    diffutils xinetd tmpwatch sysklogd logrotate man gcc-c++        \
    glibc-devel openssl-devel make

# Pacman
if !  cd pacman-3.\* ; then
  echo "==> Installing Pacman!"
  rm -f /tmp/pacman-latest.tar.gz
  wget -O /tmp/pacman-latest.tar.gz \
    http://atlas.bu.edu/~youssef/pacman/sample_cache/tarballs/pacman-latest.tar.gz
  tar xzf /tmp/pacman-latest.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd pacman-3.* && . ./setup.sh && cd ..

# VDT Components .. 
for Component in Globus-Base-Data-Server Globus-Base-SDK MyProxy; do
  echo "==> Checking/Installing: $Component"
  pacman -get http://vdt.cs.wisc.edu/vdt_200_cache:$Component || echo "==> Failed!"
done

# Setup
. setup.sh
vdt-ca-manage setupca --location root --url vdt

exit 0

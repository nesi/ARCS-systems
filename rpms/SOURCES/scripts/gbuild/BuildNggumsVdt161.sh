#!/bin/sh
# BuildNggumsVdt161.sh	APAC GUMS gateway build from VDT Repository.
#			Graham Jenkins <graham@vpac.org> Aug 2006. Rev: 20070511

#
# PATH, environment, id-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_EDG_CRL_UPDATE=y    \
VDTSETUP_EDG_MAKE_GRIDMAP=y   VDTSETUP_ENABLE_GATEKEEPER=n \
VDTSETUP_ENABLE_GRIDFTP=n     VDTSETUP_ENABLE_GRIS=n       \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_GRIS_AUTH=n         \
VDTSETUP_INSTALL_CERTS=r      VDTSETUP_ENABLE_GUMS=y       \
GUMS_USES_TOMCAT_55=y
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's
echo "==> Installing Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install vim-minimal dhclient openssh-clients openssl097a   \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap libXp   \
            tcsh openssh-server sudo lsof slocate bind-utils telnet   \
            gcc vixie-cron anacron crontabs diffutils xinetd tmpwatch \
            sysklogd logrotate compat-libstdc++-33 compat-libcom_err  \
            man gcc-c++ $Extras

#
# Apache keys
mkdir -p /etc/grid-security/http
for F in cert key ; do
  [ ! -s /etc/grid-security/host$F.pem ] && echo "Missing Host Cert/Key!"   && exit 1
  cp -p /etc/grid-security/host$F.pem /etc/grid-security/http/http$F.pem
  chown daemon:daemon /etc/grid-security/http/http$F.pem
done

#
# Pacman, VDT
mkdir -p /opt/vdt; cd /opt/vdt
if [ ! -d pacman-3.19 ]; then
  echo "==> Installing Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/pacman-3.19.tar.gz &&
  tar xzf pacman-3.19.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd pacman-3.19 && source setup.sh && cd ..

#
# VDT Components
for Component in GUMS MyProxy Fetch-CRL ; do
  echo "==> Checking/Installing: $Component"
  pacman -pretend-platform linux-rhel-4 $ProxyString \
    -get http://www.grid.apac.edu.au/repository/mirror/vdt-1.6.1.mirror:$Component || echo "==> Failed!"
done

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman   -pretend-platform linux-rhel-4 $ProxyStrin -update CA-Certificates

#
# Install startup scripts, edit my.cnf, save original gums.config file
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
grep "^\[mysql\]" /opt/vdt/mysql/var/my.cnf >/dev/null ||  sed --in-place=.ORI -e '$ a \
\
[mysql] \
password
' /opt/vdt/mysql/var/my.cnf
[ ! -f /opt/vdt/vdt-app-data/gums/gums.config.ORI ]                                  && 
  echo "==> Saving: gums.config  as: /opt/vdt/vdt-app-data/gums/gums.config.ORI"     &&
  cp /opt/vdt/vdt-app-data/gums/gums.config /opt/vdt/vdt-app-data/gums/gums.config.ORI 
. /etc/profile ; vdt-control --force --on && echo "==> Installed: startup scripts"

#
# Wrapup
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
exit 0

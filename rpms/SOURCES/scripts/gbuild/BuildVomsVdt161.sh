#!/bin/sh
# BuildVomsVdt161.sh APAC VOMRS server build from VDT Repository.
#		     Graham Jenkins <graham@vpac.org> Aug. 2006. Rev'd: 20070512

#
# PATH, environment, id-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_EDG_CRL_UPDATE=y    \
VDTSETUP_EDG_MAKE_GRIDMAP=y   VDTSETUP_ENABLE_GATEKEEPER=n \
VDTSETUP_ENABLE_GRIDFTP=n     VDTSETUP_ENABLE_GRIS=n       \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_GRIS_AUTH=n         \
VDTSETUP_INSTALL_CERTS=r      VDTSETUP_ENABLE_VOMS=y       \
VDT_ALLOW_UNSUPPORTED=y
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's
echo "==> Installing Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install vim-minimal dhclient openssh-clients openssl097a          \
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
# Pacman, java-version adjustment, VDT post-install
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  cat <<-EOF >/opt/vdt/post-setup/APAC01.sh
	export JAVA_HOME="\`echo \$JAVA_HOME            |sed -e 's/jdk1.4/jdk1.5/g'\`"
	export PATH="\`echo \$PATH                      |sed -e 's/jdk1.4/jdk1.5/g'\`"
	export MANPATH="\`echo \$MANPATH                |sed -e 's/jdk1.4/jdk1.5/g'\`"
	export LD_LIBRARY_PATH="\`echo \$LD_LIBRARY_PATH|sed -e 's/jdk1.4/jdk1.5/g'\`"
	EOF
  chmod a+xr /opt/vdt/post-setup/APAC01.sh
  echo "==> Created: /opt/vdt/post-setup/APAC01.sh"
fi
if [ ! -d pacman-3.19 ]; then
  echo "==> Installing Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/pacman-3.19.tar.gz &&
  tar xzf pacman-3.19.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd pacman-3.19 && source setup.sh && cd ..

#   
# VDT Components
for Component in JDK-1.5 VOMS Unsup-VOMRS Fetch-CRL ; do
  echo "==> Checking/Installing: $Component"
  pacman -pretend-platform linux-rhel-4 $ProxyString \
    -get http://vdt.cs.wisc.edu/vdt_161_cache:$Component || echo "==> Failed!"
done 

#
# IGTF Certificate Check/Update
echo   "==> Certificate Check/Update"
pacman -pretend-platform linux-rhel-4 $ProxyString -update CA-Certificates

#
# Install startup scripts
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
. /etc/profile
vdt-register-service --name vomrs --type init --enable --init-script /opt/vdt/vomrs/etc/init.d/vomrs
vdt-control --force --on && echo "==> Installed: startup scripts"

#
# Wrapup
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
exit 0

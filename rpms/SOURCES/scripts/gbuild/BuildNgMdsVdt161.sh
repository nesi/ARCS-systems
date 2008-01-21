#!/bin/sh
# BuildNgMdsVdt161.sh	APAC MDS gateway build from VDT 1.6.x cache.
#			Installs Globus-WS with PRIMA and APAC-specific
#			additions on a minimal CentOS 4.4 or similar machine.
#			Daniel Cox <daniel.cox@sapac.edu.au> Apr 2007, Rev 20070512

#
# PATH, environment, id-check, hosts-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_EDG_CRL_UPDATE=y    \
VDTSETUP_EDG_MAKE_GRIDMAP=y   VDTSETUP_ENABLE_GATEKEEPER=n \
VDTSETUP_ENABLE_GRIDFTP=y     VDTSETUP_ENABLE_GRIS=n       \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_GRIS_AUTH=n         \
VDTSETUP_INSTALL_CERTS=r      VDTSETUP_ENABLE_WS_CONTAINER=y
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
grep `hostname` /etc/hosts 2>/dev/null | grep -v "^#" | head -1 | awk '{
  if(length($1)<7) exit 0; if($1=="127.0.0.1") exit 0 ; exit 1}' \
                      && echo "==> Host address must appear in /etc/hosts!" && exit 2   
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's, PBS client
echo "==> Installing Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install vim-minimal dhclient openssh-clients        \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap libXp   \
            tcsh openssh-server sudo lsof slocate bind-utils telnet   \
            gcc vixie-cron anacron crontabs diffutils tmpwatch \
            sysklogd logrotate man compat-libstdc++-33   \
            compat-libcom_err openssl097a gcc-c++ $Extras

#
# Pacman, port-range adjustment, java-version adjustment, VDT
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  cat <<-EOF >/opt/vdt/post-setup/APAC01.sh
	export GLOBUS_TCP_PORT_RANGE=$TcpRange
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
for Component in JDK-1.5 Globus-WS Fetch-CRL ; do
  echo "==> Checking/Installing: $Component"
  pacman -pretend-platform linux-rhel-4 $ProxyString \
    -get http://www.grid.apac.edu.au/repository/mirror/vdt-1.6.1.mirror:$Component || echo "==> Failed!"
done

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman   -pretend-platform linux-rhel-4 $ProxyString -update CA-Certificates

#
# Install startup scripts, work-around for MySQL timeout, PRIMA configuration files
sed --in-place=.ORI -e '/WSC_PORT/ s/9443/8443/' /opt/vdt/post-install/globus-ws
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
. /etc/profile; vdt-control --force --on && echo "==> Installed: startup scripts"

#
# Server Configuration
File=/opt/vdt/globus/etc/globus_wsrf_core/server-config.wsdd
if ! grep publishHostName $File >/dev/null 2>&1; then
  sed --in-place=.ORI -e \
   '/<globalConfiguration>/a\        <parameter name="publishHostName" value="true"/>'\
                                                                               $File &&
   echo "==> Edited $File"
fi

#
# Wrapup
[ -x  /usr/local/sbin/SecureMdsVdt161.sh ] && /usr/local/sbin/SecureMdsVdt161.sh Supress
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
echo "==> When Ready, do: service globus-ws stop; service mysql restart; service globus-ws start"
exit 0

#!/bin/sh
# BuildNgdataVdt161.sh	APAC NGDATA gateway build from VDT 1.6.x cache.
#			Installs Globus-Base-Data-Server with PRIMA and APAC-specific
#			additions on a minimal CentOS 4.4 or similar machine.
#			Graham Jenkins <graham@vpac.org> Dec 2006, Rev 20070512

#
# PATH, environment, id-check, hosts-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_ENABLE_GRIDFTP=y    \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_INSTALL_CERTS=r     \
VDTSETUP_EDG_CRL_UPDATE=y
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
grep `hostname` /etc/hosts 2>/dev/null | grep -v "^#" | head -1 | awk '{
  if(length($1)<7) exit 0; if($1=="127.0.0.1") exit 0 ; exit 1}' \
                      && echo "==> Host address must appear in /etc/hosts!" && exit 2   
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's
echo "==> Installing Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install SRB-Client kernel-tcp-tune nmap                    \
            vim-minimal dhclient openssh-clients openssl097a          \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap libXp   \
            tcsh openssh-server sudo lsof slocate bind-utils telnet   \
            gcc vixie-cron anacron crontabs diffutils xinetd tmpwatch \
            sysklogd logrotate compat-libstdc++-33 compat-libcom_err  \
            man gcc-c++ $Extras

#
# Pacman, port-range adjustment, VDT
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
if [ ! -f /opt/vdt/post-setup/APAC01.sh ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  echo "export GLOBUS_TCP_PORT_RANGE=$TcpRange" >/opt/vdt/post-setup/APAC01.sh
  chmod a+xr /opt/vdt/post-setup/APAC01.sh
  echo "==> Created: /opt/vdt/post-setup/APAC01.sh"
fi
if [ ! -d pacman-3.19 ]; then
  echo "==> Installing Pacman!"
  wget http://physics.bu.edu/pacman/sample_cache/tarballs/pacman-3.19.tar.gz &&
  tar xzf pacman-3.19.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd pacman-3.19 && source setup.sh && cd ..

for Component in Globus-Base-Data-Server GSIOpenSSH PRIMA Fetch-CRL ; do
  echo "==> Checking/Installing: $Component"
  pacman -pretend-platform linux-rhel-4 $ProxyString \
    -get http://www.grid.apac.edu.au/repository/mirror/vdt-1.6.1.mirror:$Component || echo "==> Failed!"
done 

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman   -pretend-platform linux-rhel-4 $ProxyString -update CA-Certificates

#
# Install startup scripts and PRIMA configuration files
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
. /etc/profile
grep status /opt/vdt/post-install/sshd >/dev/null ||
sed --in-place=.ORI -e '/GLOBUS_LOCATION=/i\. /etc/profile' \
                    -e '/case/a\    status)\
    ps -f -p `cat $PID_FILE 2>/dev/null` >/dev/null 2>&1 &&\
      echo  "gsisshd is running..."                      && exit 0\
    echo    "gsisshd is stopped   "                      && exit 3\
    ;;\
'                   -e 's%start|%status|start|%'  /opt/vdt/post-install/sshd    
vdt-register-service --name gsisshd --type init --enable --protocol tcp \
                     --init-script /opt/vdt/post-install/sshd
chkconfig --del sshd
vdt-control --force --on && echo "==> Installed: startup scripts"
if [ ! -f /etc/grid-security/prima-authz.conf ] ; then
  /opt/vdt/vdt/setup/configure_prima
  cp $VDT_LOCATION/post-install/gsi-authz.conf   /etc/grid-security/
  cp $VDT_LOCATION/post-install/prima-authz.conf /etc/grid-security/
  echo "==> You must insert your GUMS server name in: /etc/grid-security/prima-authz.conf!"
fi

#
# Wrapup
echo "==> Re-loading: xinetd"
chkconfig --add syslog; service syslog condrestart; service xinetd reload
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
service gsissh status >/dev/null 2>&1 && exit 0
echo "==> Stopping: sshd   and Starting: gsisshd"
service sshd stop; service gsisshd start
exit 0

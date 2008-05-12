#!/bin/sh
# BuildNg2Vdt181.sh	ARCS NG2 gateway build from VDT 1.8.x cache.
#			Installs Globus-WS with PRIMA and ARCS-specific
#			additions on a minimal CentOS 4 or similar machine.
#
# See: http://projects.arcs.org.au/trac/systems/wiki/HowTo/InstallNg2
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
yum install vim-minimal dhclient openssh-clients Ggateway      \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap libXp   \
            tcsh openssh-server sudo lsof slocate bind-utils telnet   \
            gcc vixie-cron anacron crontabs diffutils xinetd tmpwatch \
            sysklogd logrotate man pbs-telltail compat-libstdc++-33   \
            compat-libcom_err perl-DBD-MySQL openssl097a gcc-c++ $Extras
# check yum's return status
if (($? == 1));
then
    echo "==> yum bailed out!"
    exit 2
fi

# Torque qstat
until qstat >/dev/null 2>/dev/null ; do
  echo    "==> qstat not found or not configured!"
  echo -n "==> Enter path (e.g. /usr/local/pbs/bin), else enter 'q' .. "
  read _Ans       && [ -d "$_Ans" ] && export PATH=$PATH:$_Ans
  [ "$_Ans" = q ] && echo "==> You might want to do: yum install Gtorque-client" && exit 1
done
[ -d /usr/spool/PBS/server_logs ] && export PBS_HOME=/usr/spool/PBS

# VDT port-range adjustment
mkdir -p /opt/vdt/post-setup; cd /opt/vdt
SETTINGS=ARCS01.sh
if [ ! -f /opt/vdt/post-setup/$SETTINGS ] ; then
  until [ -n "$TcpRange" ]; do
    echo -n "==> Please enter GLOBUS_TCP_PORT_RANGE [e.g. 40000,41000] .. " 
    read TcpRange
    echo "$TcpRange" | egrep -q "^[[:digit:]]+,[[:digit:]]+$" || unset TcpRange
  done
  cat <<-EOF >/opt/vdt/post-setup/$SETTINGS
	export GLOBUS_TCP_PORT_RANGE=$TcpRange
	EOF
  chmod a+xr /opt/vdt/post-setup/$SETTINGS
  echo "==> Created: /opt/vdt/post-setup/$SETTINGS"
fi

# Pacman
PACMAN=pacman-3.21
PACMANSRC=http://projects.arcs.org.au/svn/systems/trunk/rpms/SOURCES/$PACMAN.tar.gz
if [ ! -d $PACMAN ]; then
  echo "==> Installing Pacman!"
  which wget > /dev/null || ( echo "wget not in path!" && exit 1 )
  wget $PACMANSRC &&
  tar xzf $PACMAN.tar.gz && echo "==> Done!" || echo "==> Failed!"
fi
cd $PACMAN && source setup.sh && cd ..

#
# VDT Components
PLATFORM="-pretend-platform linux-rhel-4"
VDTMIRROR=http://projects.arcs.org.au/mirror/vdt/vdt_181_cache
for Component in JDK-1.5 Globus-WS PRIMA-GT4 Fetch-CRL Globus-WS-PBS-Setup ; do

  # Pacman 3.21 complains about -pretend-platform when installation exists
  # ie. after first component is installed!
  [ -f o..pacman..o/platform ] && unset PLATFORM

  echo "==> Checking/Installing: $Component"
  pacman $PLATFORM $ProxyString \
    -get $VDTMIRROR:$Component || echo "==> Failed!"
done

#
# IGTF Certificate Check/Update
echo   "==> Performing: Certificate Check/Update"
pacman $PLATFORM $ProxyString -update CA-Certificates

#
# Install environment
sed --in-place=.ORI -e '/WSC_PORT/ s/9443/8443/' /opt/vdt/post-install/globus-ws
for File in setup.sh setup.csh ; do
  [ ! -s /etc/profile.d/vdt_$File ] && ln -s /opt/vdt/$File /etc/profile.d/vdt_$File &&
                                       echo "==> Created: /etc/profile.d/vdt_$File"
done
. /etc/profile

# work-around for MySQL timeout
grep "^wait_timeout"  /opt/vdt/mysql/var/my.cnf >/dev/null ||
  sed --in-place=.ORI -e '/^\[mysqld\]/ a \
wait_timeout=2764800
' /opt/vdt/mysql/var/my.cnf

vdt-control --force --on && echo "==> Installed: startup scripts"

# PRIMA configuration
if [ ! -f /etc/grid-security/prima-authz.conf ] ; then
  until [ -n "$Gums_Server" ] ; do
    echo -n "==> Please enter the name of your GUMS server [e.g. nggums.vpac.org ] .. "
    read Gums_Server 
  done
  /opt/vdt/vdt/setup/configure_prima_gt4 --enable --gums-server $Gums_Server
fi

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
# sudoers
grep -v "^#" /etc/sudoers | grep requiretty >/dev/null        &&
  echo "==> Commenting: 'requiretty' line in /etc/sudoers"    &&
  sed --in-place=.ORI -e '/requiretty/ s/^/#/' /etc/sudoers
if grep GLOBUSUSERS /etc/sudoers >/dev/null ; then
  :
else
  echo "==> Updating: /etc/sudoers"
  cat >>/etc/sudoers<<-EOF
	Runas_Alias GLOBUSUSERS = ALL, !root
	daemon ALL=(GLOBUSUSERS) \
	       NOPASSWD: /opt/vdt/globus/libexec/globus-job-manager-script.pl *
	daemon ALL=(GLOBUSUSERS) \
	       NOPASSWD: /opt/vdt/globus/libexec/globus-gram-local-proxy-tool *
	EOF
fi

#
# Wrapup
chkconfig --add pbs-logmaker; service pbs-logmaker start
echo "==> Re-starting: xinetd"
chkconfig --add xinetd; service xinetd start; service xinetd reload

echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &

echo "==> You may now need to copy: /usr/local/src/pbs.pm.APAC"
echo "==> To: /opt/vdt/globus/lib/perl/Globus/GRAM/JobManager/pbs.pm and edit"
echo "==> Then: service globus-ws stop; service mysql restart; service globus-ws start"
exit 0

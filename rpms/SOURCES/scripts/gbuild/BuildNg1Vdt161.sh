#!/bin/sh
# BuildNg1Vdt161.sh	APAC NG1 gateway build from VDT 1.6.x cache.
#			Installs Globus with PRIMA and APAC-specific
#			additions on a minimal CentOS 4.4 or similar machine.
#			Graham Jenkins <graham@vpac.org> Dec 2006, Rev 20070512

#
# PATH, environment, id-check, hosts-check
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin   \
VDTSETUP_AGREE_TO_LICENSES=y  VDTSETUP_EDG_CRL_UPDATE=y    \
VDTSETUP_EDG_MAKE_GRIDMAP=n   VDTSETUP_ENABLE_GATEKEEPER=y \
VDTSETUP_ENABLE_GRIDFTP=y     VDTSETUP_ENABLE_GRIS=y       \
VDTSETUP_ENABLE_ROTATE=y      VDTSETUP_GRIS_AUTH=n         \
VDTSETUP_INSTALL_CERTS=r
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"

#
# RPM's, PBS client
echo "==> Installing Prerequisite and Useful RPMs"
[ "`uname -i`" = x86_64 ] && Extras="glibc-devel.i386 glibc-devel.x86_64" || Extras=glibc-devel
yum install Ggateway Gpulse vim-minimal dhclient openssh-clients libXp    \
            vim-enhanced iptables ntp yp-tools mailx nss_ldap openssl097a \
            tcsh openssh-server sudo lsof slocate bind-utils telnet       \
            gcc vixie-cron anacron crontabs diffutils xinetd tmpwatch     \
            sysklogd logrotate compat-libstdc++-33 compat-libcom_err      \
            man gcc-c++ $Extras
until qstat >/dev/null 2>/dev/null ; do
  echo    "==> qstat not found or not configured!"
  echo -n "==> Enter path (e.g. /usr/local/pbs/bin), else enter 'q' .. "
  read _Ans       && [ -d "$_Ans" ] && export PATH=$PATH:$_Ans
  [ "$_Ans" = q ] && echo "==> You might want to do: yum install Gtorque-client" && exit 1
done

#
# Pacman, VDT Post-setup
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

#   
# VDT Components
for Component in VDT-Gatekeeper PRIMA Fetch-CRL Globus-PBS-Setup ; do
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
. /etc/profile ; vdt-control --force --on && echo "==> Installed: startup scripts"
if [ ! -f /etc/grid-security/prima-authz.conf ] ; then
  /opt/vdt/vdt/setup/configure_prima
  cp $VDT_LOCATION/post-install/gsi-authz.conf   /etc/grid-security/
  cp $VDT_LOCATION/post-install/prima-authz.conf /etc/grid-security/
  echo "==> You must insert your GUMS server name in: /etc/grid-security/prima-authz.conf!"
fi

#
# Local Modifications
File=/etc/syslog.conf
if ! grep Grid_ $File >/dev/null 2>&1; then
  ( echo;echo "# APAC-specific"
    echo "local6.info				/var/log/Grid_.log" )   >> $File &&
  echo "==> Modified: $File"
fi   
File=/opt/vdt/globus/etc/globus-job-manager.conf
if ! grep scratch-dir-base $File >/dev/null 2>&1; then
  ( echo;echo -n "        -scratch-dir-base \$(HOME)/.globus/scratch" ) >> $File &&
  echo "==> Defined scratch-dir-base in: $File"
fi

File=/opt/vdt/globus/share/globus_gram_job_manager/pbs.rvf
awk '{if($1=="Attribute:") if($2=="queue") {$0="# "$0; N=NR+1}
      if($1=="Values:"   ) if(NR==N      ) {$0="# "$0}
      print $0                                            }'<$File>/tmp/`basename $0`.$$
if ! cmp $File /tmp/`basename $0`.$$ >/dev/null 2>&1 ; then
  cp $File $File.`date +%s` && cp /tmp/`basename $0`.$$ $File &&
  echo "==> Removed queue-name limitation in: $File"
fi
if ! grep "^Attribute: module" $File >/dev/null 2>&1 ; then
  ( echo; echo "Attribute: module"; echo "Description: \"APAC specific.\""
    echo "ValidWhen: GLOBUS_GRAM_JOB_SUBMIT" )        >>$File &&
  echo "==> Added module attribute in: $File"
fi
if ! grep "^Attribute: jobname" $File >/dev/null 2>&1 ; then
  ( echo; echo "Attribute: jobname"; echo "Description: \"APAC specific.\""
    echo "ValidWhen: GLOBUS_GRAM_JOB_SUBMIT" )        >>$File &&
  echo "==> Added jobname attribute in: $File"
fi

#
# Syslog, xinetd, gris
chkconfig --add syslog; service syslog condrestart
chkconfig --add xinetd; service xinetd start; service xinetd reload
chkconfig --del gris  ; service gris   stop

#
# Wrapup
echo "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp &&
  nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron>/dev/null &
echo "==> You may now need to copy: /usr/local/src/pbs.pm.APAC-GT2"
echo "==> To: /opt/vdt/globus/lib/perl/Globus/GRAM/JobManager/pbs.pm and edit"
echo "==> When ready, do: service xinetd reload"
exit 0

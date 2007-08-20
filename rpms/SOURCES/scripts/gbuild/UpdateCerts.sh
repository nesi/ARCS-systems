#!/bin/sh
# UpdateCerts.sh	APAC Client/Gateway Certificate Check/Update
#			Graham Jenkins <graham@vpac.org> Feb 2007. Rev: 20070314

#
# Define 'fail' function, set environment, perform usage checks
fail () {
  echo "==> $@"; exit 1
}
. /etc/profile
[ -n "$http_proxy" ] && ProxyString="-http-proxy $http_proxy" &&echo "==> Using Proxy: $http_proxy"
[ `id -un` = root ]                                    || fail "You must be 'root' to run this program!"
vdt-version 2>/dev/null | grep Certificates >/dev/null || fail "CA-Certificate package not installed!"
cd $PACMAN_LOCATION && source setup.sh && cd ..        || fail "Can't find Pacman!"

#
# Ascertain platform, perform the check/update, then fetch CRLs
grep Zod /etc/redhat-release >/dev/null 2>&1 &&  Platform=linux-fedora-4 || Platform=linux-rhel-4
echo   "==> Performing: Certificate Check/Update"
pacman   -pretend-platform $Platform $ProxyStrin -update CA-Certificates
echo   "==> Running: /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron"
cd /tmp && nohup /opt/vdt/fetch-crl/share/doc/fetch-crl-2.6.2/fetch-crl.cron >/dev/null &
exit 0

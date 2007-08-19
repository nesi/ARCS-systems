Summary: GridPortlets configuration for APAC gateways
Name: APAC-gateway-config-gridportlets
Version: 0.1
Release: 1
Copyright: APAC
Group: Applications/Internet
Requires: APAC-gridsphere, APAC-gateway-host-certificates
BuildArch: noarch

%description
Sets up portalcert.pem and portalkey.pem for gridportlets proxy retrieval.

%pre
CERT_DIR="/etc/grid-security"
HOST_CERT="$CERT_DIR/hostcert.pem"
HOST_KEY="$CERT_DIR/hostkey.pem"

[ ! -f $HOST_CERT ] && { echo "You haven't got a host certificate at $HOST_CERT.  Please set this up before installing." >&2; exit 1; }
[ ! -f $HOST_KEY ] && { echo "You haven't got a host key at $HOST_KEY.  Please set this up before installing." >&2; exit 1; }

# otherwise we'll always fail!
/bin/true

%post
CERT_DIR="/etc/grid-security"
HOST_CERT="$CERT_DIR/hostcert.pem"
HOST_KEY="$CERT_DIR/hostkey.pem"

cp $HOST_CERT $CERT_DIR/portalcert.pem
cp $HOST_KEY $CERT_DIR/portalkey.pem
chown tomcat:tomcat $CERT_DIR/portal{cert,key}.pem

mkdir -p /usr/local/lib/gridpulse
echo APAC-gridportlets >> /usr/local/lib/gridpulse/system_packages.pulse

%postun
perl -ni -e "print unless /^APAC-gridportlets/;" /usr/local/lib/gridpulse/system_packages.pulse


%files

%changelog


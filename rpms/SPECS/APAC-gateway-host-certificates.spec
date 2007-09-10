Summary: Indicates that you've got your hostcert.pem and hostkey.pem setup
Name: APAC-gateway-host-certificates
Version: 0.1
Release: 1
License: APAC
Group: Applications/Internet
Provides: /etc/grid-security/hostcert.pem, /etc/grid-security/hostkey.pem
Requires: openssl
BuildArch: noarch

%description
Indicates that you've got your hostcert.pem and hostkey.pem setup

%pre
CERT="/etc/grid-security/hostcert.pem"
KEY="/etc/grid-security/hostkey.pem"

if ! CERT_MOD=$(openssl x509 -in $CERT -noout -modulus)
then
	echo "Couldn't get modulus from $CERT"
	echo "Please check that it's a valid x509 certificate"

	exit 1
fi

if ! KEY_MOD=$(openssl rsa -in $KEY -noout -modulus)
then
	echo "Couldn't get modulus from $KEY"
	echo "Please check that it's a valid rsa private key"

	exit 1
fi

if [ "$CERT_MOD" != "$KEY_MOD" ]; then
	echo "$CERT does not match $KEY"
	echo "Please install a matching certificate and key"

	exit 1
fi

%files

%changelog


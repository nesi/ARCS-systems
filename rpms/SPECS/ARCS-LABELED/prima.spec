%define PREFIX /usr
%define GLOBUS_LOCATION %{PREFIX}/globus
%define PRIMA_LOCATION %{PREFIX}/prima

Summary:        PRIMA
Name:           prima
Version:        0.4
Release:        2.arcs
License:        custom
Group:          Applications/Internet
Source:         osg-%{name}-%{version}.arcs.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    compat-gcc-34, globus-libraries, compat-gcc-34-c++
Requires:       globus-libraries, globus-gridftp-server

%description
PRIMA ( PRIvilege Management and Authorization) is a system which provides enhanced grid security.

PRIMA is both a comprehensive grid security model and system. The model describes how privileges are created, distributed, shared, selected, and bound to resource requests. The model also describes how the privileges relate to policies defined by resource managers and how the intent of the security system can be enforced.

In PRIMA, a privilege is a platform independent, self contained representation of a fine-grained right. PRIMA achieves platform independence of privileges by externalizing fine-grained access rights to resource objects from the resource's internal representation.

For example, a privilege for a file access right is abstracted from the way file access rights are stored in the file meta information by the operating system. The PRIMA representation uses a standard XML-based language to encode the externalized form of the privilege. A privilege is self-contained in that its meaning is fully determined by the information contained in the privilege.

PRIMA provides for the grid layer management and delegation of privileges on a userto -user and administrator-to-user basis. The holder of privileges can selectively provide individual privileges to grid resources when requesting access. This enables least privilege access to resources and ensures that the user has fine-grained control over resource usage of requested services. Resource administrators create and manage polices for their resources via grid layer PRIMA mechanisms. The user-supplied privileges are combined with the administrator-provided policies to render a dynamic authorization decision.

This package is designed to be used with the ARCS gridFTP rpms.

The install can be (optionally) controlled with one environment variable:
GUMSSERVER      the full hostname of the GUMS server the installtion should use.

If this variable is not set, the prima-authz.conf file will not be written.

%prep
%setup -q -n osg-%{name}-%{version}.arcs

%build
export GLOBUS_LOCATION=%{GLOBUS_LOCATION}
#export PRIMA_LOCATION=/
export PRIMA_LOCATION=%{PRIMA_LOCATION}
export CC=/usr/bin/gcc34
export CXX=/usr/bin/g++34
if test ! -e %{GLOBUS_LOCATION}/include/openssl ; then
    ln -s %{GLOBUS_LOCATION}/include/gcc32dbg/openssl %{GLOBUS_LOCATION}/include/
fi
sh arcs-prima-build.sh -i %{_tmppath}/%{name}-root/%{PRIMA_LOCATION} -g %{GLOBUS_LOCATION}

%install

find $RPM_BUILD_ROOT/%{PRIMA_LOCATION}/lib -name '*la' -exec sh -c 'cat $1 | sed "s|%{_tmppath}/%{name}-root||g" > $1.bak && mv $1.bak $1' {} {} \; ;
find $RPM_BUILD_ROOT/%{PRIMA_LOCATION}/lib -name '*la' -exec sh -c 'cat $1 | sed "s|/tmp/globus-4.0.6-2.arcs-buildroot||g" > $1.bak && mv $1.bak $1' {} {} \; ;

%post
if ! grep -q %{PRIMA_LOCATION}/lib /etc/ld.so.conf; then
        echo "%{PRIMA_LOCATION}/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

## configuration

mkdir -p /etc/grid-security
touch /etc/grid-security/gsi-authz.conf
cat <<-EOF > /etc/grid-security/gsi-authz.conf
globus_mapping %{PRIMA_LOCATION}/lib/libprima_authz_module_gcc32dbg globus_gridmap_callout
EOF

if [[ $GUMSSERVER ]]; then
%define GUMSSERVER $GUMSSERVER
touch /etc/grid-security/prima-authz.conf

cat <<-EOF > /etc/grid-security/prima-authz.conf
# PRIMA Module configuration file
# this file configures what identity mapping service the prima module should contact
# format is simply: 
# IMS_contact service-url

# This is the identity mapping server, it performs a mapping based on the gridmap file on the service host
imsContact https://%{GUMSSERVER}:8443/gums/services/GUMSAuthorizationServicePort

#A directory that contains identity certificates of attribute certificate issuers (e.g., voms servers)
# optional
#issuerCertDir  /etc/grid-security/vomsdir

#should the signature on received attribute certificates be verified 
#(recommended, but requires issuerCertDir in most cases)
# optional, default is "true" if ommitted
#verifyAC true
verifyAC false

#host certs
serviceCert /etc/grid-security/hostcert.pem
serviceKey  /etc/grid-security/hostkey.pem
caCertDir   /etc/grid-security/certificates

# logging levels supported are debug, info, error, none
#logLevel    debug
logLevel    info

#SAML XML schema directory
samlSchemaDir %{PRIMA_LOCATION}/etc/opensaml/

EOF
fi
## end configuration

%clean
rm -rf $RPM_BUILD_ROOT

%files
#%{Buildroot}/*
%{PRIMA_LOCATION}/*

%changelog
* Thu Feb 28 2008 Florian Goessmann <florian@iec.org>
- added gridftp-server dependency
* Mon Feb 11 2008 Florian Goessmann <florian@ivec.org>
- first release

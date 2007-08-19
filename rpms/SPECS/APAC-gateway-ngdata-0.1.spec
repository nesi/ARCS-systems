Summary: Provides basic ngdata functionality
Name: APAC-gateway-ngdata
Version: 1.0
Release: 1
Copyright: APAC or QUT?
Group: Applications/Internet
Requires: APAC-globus-gridftp-server, APAC-globus-gsi-openssh-server, ca_APAC, APAC-gateway-crl-update, APAC-gateway-gridpulse, APAC-gateway-gridmap-sync, APAC-gateway-host-certificates
BuildArch: noarch

%description
This is a meta RPM to pull in the dependencies for basic ngdata functionality

%post
chkconfig xinetd on

%files

%changelog


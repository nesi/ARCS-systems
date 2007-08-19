Summary: ngportal rpm to make a new ngportal machine
Name: APAC-gateway-ngportal
Version: 1.0
Release: 2
Copyright: APAC or QUT?
Group: Applications/Internet
Requires: APAC-gridportlets, ca_APAC, APAC-gateway-config-ant, APAC-gateway-config-mod_jk, APAC-gateway-config-gridsphere, Gpulse, APAC-gateway-crl-update, APAC-gateway-host-certificates
BuildArch: noarch

%description
This is a meta RPM to pull in the dependencies for a 'stock' ngportal image

%files

%post
# make sure services are configured to start
for i in httpd tomcat; do
	chkconfig --add $i
	chkconfig $i on
done

#Copy portal cert
# TODO: find out what this is for
#cp /etc/grid-security/hostcert.pem /etc/grid-security/portalcert.pem
#cp /etc/grid-security/hostkey.pem  /etc/grid-security/portalkey.pem
#chown tomcat:tomcat /etc/grid-security/portalcert.pem
#chown tomcat:tomcat /etc/grid-security/portalkey.pem

%changelog
* Mon Apr 16 2007 Ashley Wright
- Depends on Gpulse instead of gridpulse
* Tue Nov 14 2006 Andrew Sharpe
- changed name
- added service settings
- changed to use new dependencies
* Thu Aug 18 2006 Ashley Wright <a2.wright@qut.edu.au>
- Moved all VOMRS stuff to a different RPM
* Thu Aug 17 2006 Ashley Wright <a2.wright@qut.edu.au>
- Changes to 03-gridmap-gen.cron
- Added copying of portal cert
* Wed May 03 2006 Matthew watts <mj.watts@qut.edu.au>
- Initial creation of spec file and rpm


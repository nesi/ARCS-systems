Summary: The APAC CA certificates and crl tool
Name: APAC-gateway-gridpulse
Version: 0.1
Release: 1
Copyright: GPL
Group: Applications/Internet
BuildRoot: /tmp/%{name}-buildroot
Requires: vixie-cron

%description
Installs the APAC gridpulse script and cron entry to report on gateway health.

%install
mkdir -p $RPM_BUILD_ROOT/usr/bin
cat <<EOF > $RPM_BUILD_ROOT/usr/bin/gridpulse
#!/bin/sh
# gridpulse     Performs one set of system/application tests, the exits.
#               Should be invoked from cron at 20 minute intervals, with output
#               emailed to a monitoring address.
#               Graham Jenkins <grahjenk@vpac.org> Last changed: 20060905

#
# PATH, etc.
PATH=/usr/bin:/bin:/usr/sbin:/usr/sbin:/sbin:\$PATH
Destination=grid_pulse@vpac.org
Status=OK
Disposition="Mail -s \"\`uname -n\` Periodic System Check\" \$Destination"
[ -t 0 ] && Disposition=cat
. /etc/profile >/dev/null 2>&1

seconds() {
  date -d "\$1" +%s
}

#
# System Information
( for Cmd in "uname -nrv" "cat /etc/redhat-release" "uptime|sed -e 's/^ //'" \
    "xm dmesg 2>/dev/null |
       awk -F '(' '{if(\\\$1~/Xen version/){sub(\" \",\"\",\\\$1);print \\\$1}}'"  \
    "xm info  2>/dev/null | awk -F : '/total_memory/ {print \\\$0}'"           \
    "xm info  2>/dev/null | awk -F : '/free_memory/  {print \\\$0}'"           \
    "df -k /|tail -1"                                                        \
    "ls -lL /etc/grid-security/grid-mapfile                     2>/dev/null| 
       awk '{if(NR==1)if(NF>2)print \\\$NF,\\\$(NF-3),\\\$(NF-2),\\\$(NF-1)}'"       \
    "ls -lL \\$GLOBUS_LOCATION/lib/perl/Globus/GRAM/JobManager/pbs.pm 2>/dev/null|
       awk '{if(NR==1)if(NF>2)print \\\$NF,\\\$(NF-3),\\\$(NF-2),\\\$(NF-1)}'"       \
    "ls -la /opt/.ng1_vdt.stamp                                 2>/dev/null| 
       awk '{if(NR==1)if(NF>2)print \\\$NF,\\\$(NF-3),\\\$(NF-2),\\\$(NF-1)}'"       \
    "java -version >/dev/null 2>&1 && java -version 2>&1 | head -1"          \
    "globus-version>/dev/null 2>&1 && echo -n globus-version' ' 
                                   && globus-version"                       ; do
    [ -n "\`eval \$Cmd\`" ] && echo "Info:    \`eval \$Cmd\`"
  done

#
# Packages
  for Pkg in apache-ant globus pbs-telltail torque-client SRB-Slave_Server   \
    j2sdk jdk                                                              ; do
    rpm -q \$Pkg >/dev/null && echo "Info:    # \`eval rpm -q \$Pkg|sort|tail -1\`"
  done

#
# Raid information
  for Controller in \`ipssend getversion 2>/dev/null |
                     awk '/^ServeRAID Controller Number/ {print \$NF}'\` ; do
    ipssend getconfig \$Controller ld 2>/dev/null |
      awk '/Status of logical drive/ {if(\$NF!~"OKY")exit 1}' && \
      echo "Info:    RAID (Controller \$Controller) is: OK"   && continue
      echo "Info:    RAID (Controller \$Controller) is: Not OK"; Status="Not OK"
  done

#
# For each un-expired certificate, check that CRL exists and hasn't expired
  NowDate="\`date -u\`"; CrlStat=OK
  for Cert in /etc/grid-security/certificates/*.0 ; do
    EndDate="\`openssl x509 -in \$Cert -enddate -noout 2>/dev/null |
              awk -F= '{print \\\$2}'\`"    # Should check StartDate too
    [ -z "\$EndDate" ] && continue
    [ \`seconds "\$EndDate"\` -lt \`seconds "\$NowDate"\` ] && continue 
    Crl="\`echo \$Cert | awk -F. '{print \\\$1}'\`.r0"
    CrlDate="\`openssl crl -in \$Crl -nextupdate -noout 2>/dev/null|
              awk -F= '{print \\\$2}'\`"
    [ -n "\$CrlDate" ] && [ \`seconds "\$CrlDate"\` -ge \`seconds "\$NowDate"\` ] \
                                                      && continue
    echo "Info:    CRL problem ..  \$Cert"
    case "\`basename \$Cert\`" in
      1e12d831.0|21bf4d92.0 ) Status="Not OK" && CrlStat="Not OK"
    esac
  done

#
# Service status
  for Service in \`chkconfig --list |
         awk '{if(\\\$5=="3:on")if(\\\$1!="iptables")if(\\\$1!="anacron")print \\\$1}'\`; do
    case "\`service \$Service status 2>/dev/null | head -1\`" in
      *"is running"* ) echo "Service: \$Service is: OK"                     ;;
      *"is stopped"* ) echo "Service: \$Service is: Not OK"; Status="Not OK";;
      *              )                                                     ;;
    esac
  done
  echo "Service: APAC-crl-status is: \$CrlStat"

#
# Summary, send-randomisation
  echo "Summary: \`uname -n\` is: \$Status"
  [ "\$Disposition" = cat  ] || perl -e 'sleep int(180*rand())'
) 2>&1 | eval \$Disposition
exit 0

EOF

%clean
rm -rf $RPM_BUILD_ROOT

%post
if ! grep -q /usr/bin/gridpulse /var/spool/cron/root; then
	echo "3,23,43 * * * * /usr/bin/gridpulse grid_pulse@vpac.org >/dev/null 2>&1" >> /var/spool/cron/root
	/etc/init.d/crond restart
fi

%files
%defattr(755,root,root)
/usr/bin/gridpulse

%changelog


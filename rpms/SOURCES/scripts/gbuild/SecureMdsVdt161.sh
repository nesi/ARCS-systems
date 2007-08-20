#!/bin/sh
# SecureMdsVdt161.sh   APAC MDS4 Security Patches for VDT 1.6.1
#		       Gerson Galang <gerson.galang@sapac.edu.au> and
#		       Graham Jenkins <graham@vpac.org> May 2007, Rev 20070524

#
# Id-check, etc.
[ ! `id -un` = root ] && echo "==> You must be 'root' to run this program!" && exit 2
[ ! -n "$GLOBUS_LOCATION" ] &&  echo "==> GLOBUS_LOCATION not defined!"     && exit 2
[ ! -d "$GLOBUS_LOCATION/etc/globus_wsrf_mds_index" ] &&
                                       echo "==> No MDS4 components found!" && exit 2

#
# Client-side security 
echo "==> Implementing host authentication for MDS publish operations .."
cat <<-EOF >$GLOBUS_LOCATION/etc/globus_wsrf_mds_index/client-security-config.xml
	<securityConfig xmlns="http://www.globus.org">
	  <credential>
	    <cert-file value="/etc/grid-security/containercert.pem"/>
	    <key-file value="/etc/grid-security/containerkey.pem"/>
	  </credential>
	</securityConfig>
	EOF
grep client-security-config.xml $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/upstream.xml >/dev/null ||
sed --in-place=.ORI -e '/<RefreshIntervalSecs>/ a \
   <SecurityDescriptorFile>etc/globus_wsrf_mds_index/client-security-config.xml</SecurityDescriptorFile>
' $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/upstream.xml

#
# Server-side security
echo "==> Restricting hosts allowed to publish to this host .."
touch /etc/grid-security/mds-grid-mapfile
[ -s /etc/grid-security/mds-grid-mapfile ] ||
  ( echo "==> If you're performing aggregation on this host,"
    echo "==> you'll need to edit: /etc/grid-security/mds-grid-mapfile" )
grep mds-grid-mapfile $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/index-security-config.xml >/dev/null || 
  ( cp                $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/index-security-config.xml \
                      $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/index-security-config.xml.ORI
    cat <<-EOF       >$GLOBUS_LOCATION/etc/globus_wsrf_mds_index/index-security-config.xml
	<securityConfig xmlns="http://www.globus.org">
	  <auth-method>
	   <GSITransport/>
	   <GSISecureMessage/>
	   <GSISecureConversation/>
	  </auth-method>
	  <method name="queryResourceProperties">
	    <auth-method><none/></auth-method>
	  </method>
	  <method name="getResourceProperty">
	    <auth-method><none/></auth-method>
	  </method>
	  <method name="getResourceProperties">
	    <auth-method><none/></auth-method>
	  </method>
	  <method name="getMultipleResourceProperties">
	    <auth-method><none/></auth-method>
	  </method>
	  <authz value="gridmap"/>
	  <gridmap value="/etc/grid-security/mds-grid-mapfile"/>
	</securityConfig>
	EOF
  )
grep index-security-config.xml $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/server-config.wsdd >/dev/null ||
sed --in-place=.ORI -e '/mds.index.impl.DefaultIndexService/ a \
        <parameter name="securityDescriptor" value="etc/globus_wsrf_mds_index/index-security-config.xml"/>
' $GLOBUS_LOCATION/etc/globus_wsrf_mds_index/server-config.wsdd

[ "$1" != "Supress" ] && echo "==>  When ready, do:  service globus-ws stop; service globus-ws start"
exit 0

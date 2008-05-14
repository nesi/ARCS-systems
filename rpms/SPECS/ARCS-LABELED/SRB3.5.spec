%define srbroot /usr/srb
%define srbHome /var/lib/srb
%define srbSrc  SRB3_5_0
%define globuslocation /usr/srb/globus

Summary:        The Storage Resource Broker
Name:           srb
Version:        3.5.0
Release:        7.arcs
License:        Custom
Group:          Applications/File
Source:         SRB%{version}.tar.gz
Patch0:         srb3.5-destdir.patch
Patch1:         srb3.5-shib-srb.patch
Patch2:         srb3.5-securecomm.patch
URL:            http://www.sdsc.edu/srb/index.php/Main_Page
Packager:       David Gwynne <dlg@itee.uq.edu.au>, Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildRequires:  make gcc srb-psqlodbc, globus-srb-gridftp-server

%description
The Storage Resource Broker is a distributed file system (Data Grid),
based on a client-server architecture.

It replicates, syncs, archives, and provides a way to access files
and computers based on their attributes rather than just their names
or physical locations.

%package clients
Summary:    The Storage Resource Broker unix client commands (Scommands)
Group:      Applications/File
Requires:   globus-srb-libraries

%package server
Summary:    The Storage Resource Broker server
Group:      Applications/File
Prereq:     /sbin/chkconfig, /usr/sbin/useradd, /sbin/ldconfig
Requires:   globus-srb-gridftp-server, postgresql-server, srb-psqlodbc

%package install
Summary:    The Storage Resource Broker server configuration package
Group:      Applications/File
Requires:   srb-server, srb-clients

%package server-update
Summary:    The Storage Resource Broker server 3.4.2 -> 3.5.0 update package
Group:      Applications/File
Requires:   srb-server = 3.4.2

%description clients
The Storage Resource Broker is a distributed file system (Data Grid),
based on a client-server architecture.

It replicates, syncs, archives, and provides a way to access files
and computers based on their attributes rather than just their names
or physical locations.

This is the client portion, once a SRB data grid has been setup, users
can begin using the system to ingest and share files with the community.

%description server
The Storage Resource Broker is a distributed file system (Data Grid),
based on a client-server architecture.

It replicates, syncs, archives, and provides a way to access files
and computers based on their attributes rather than just their names
or physical locations.

This is the server portion.

%description install
This package provides basic configuration for the SRB server.

The configuration can be controlled by setting environment variables.
A default value will be used in case a variable is not set.

PGPORT              Port for the MCAT PostgreSQL database. Default: 5432
MCATDATA            Root directory for the MCAT database. Default: /var/lib/srb/mcat
SRB_DOMAIN          The name of the SRB Domain. Default: current hostname
SRB_ADMIN_NAME      SRB user name of the SRB administrator: Default: srbAdmin
SRB_ADMIN_PASSWD    SRB password for the administrator. Default: admin#srb
SRB_VAULT           Local directory for the local resource. Default: /var/lib/srb/Vault
SRB_LOCATION        Name of the SRB Location. Default: current hostname
SRB_ZONE            Name of the SRB zone the location belongs to. Default: current hostname
SRB_RESOURCE        Name of the local resource. Default: current hostname
SRB_NO_INCA     If set to any value, INCA test user is not created. Default: not set
SRB_INCA_DN     DN of the INCA test user. Default: /C=AU/O=APACGrid/OU=SAPAC/CN=Gerson Galang GTest

%description server-update
This package updates the server version 3.4.2 to version 3.5.

%prep
%setup -q -n %{srbSrc}

%patch0 -p1 -b .destdir
%patch1 -p2 -b .shib-srb
%patch2 -p2 -b .securecomm

%build
# real men use --prefix
export GLOBUS_LOCATION=%{globuslocation}
export LD_LIBRARY_PATH=$GLOBUS_LOCATION/lib
export CFLAGS="-I$GLOBUS_LOCATION/include -I$GLOBUS_LOCATION/include/gcc32dbg -I$GLOBUS_LOCATION/include/gcc32dbgpthr"
#%configure --enable-installdir=%{srbroot} --enable-psgmcat --enable-psghome=/usr --enable-gsi-auth --enable-globus-location=$GLOBUS_LOCATION --enable-globus-flavor=gcc32dbgpthr --enable-httpd=8080
%configure --enable-installdir=%{srbroot} --enable-psgmcat --enable-psghome=/usr --enable-gsi-auth --enable-globus-location=$GLOBUS_LOCATION --enable-globus-flavor=gcc32dbgpthr
make DBMS_INCLUDE="-I%{srbroot}/include -DPSQMCAT" DBMS_LIB="-L%{srbroot}/lib -lpsqlodbc"

cd MCAT
make DBMS_INCLUDE="-I%{srbroot}include -DPSQMCAT" DBMS_LIB="-lm -lpthread -L%{srbroot}/lib -lpsqlodbc -L%{globuslocation}/lib -lglobus_gss_assist_gcc32dbgpthr -lglobus_gssapi_gsi_gcc32dbgpthr -lglobus_gsi_credential_gcc32dbgpthr -lglobus_gsi_proxy_core_gcc32dbgpthr -lglobus_gsi_callback_gcc32dbgpthr -lglobus_oldgaa_gcc32dbgpthr -lglobus_gsi_sysconfig_gcc32dbgpthr -lglobus_gsi_cert_utils_gcc32dbgpthr -lglobus_openssl_error_gcc32dbgpthr -lglobus_openssl_gcc32dbgpthr -lglobus_proxy_ssl_gcc32dbgpthr -lssl_gcc32dbgpthr -lcrypto_gcc32dbgpthr -lglobus_common_gcc32dbgpthr -lglobus_callout_gcc32dbgpthr -lltdl_gcc32dbgpthr"

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
# The SRB build system is a load of garbage and doesnt define install targets
# for the Scommonds, so we do it by hand.
mkdir -p $RPM_BUILD_ROOT%{srbroot}
make DESTDIR="$RPM_BUILD_ROOT" install
mkdir -p $RPM_BUILD_ROOT%{_bindir}
mkdir -p $RPM_BUILD_ROOT%{_mandir}/man1
mkdir -p $RPM_BUILD_ROOT/var/lib/srb
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/obj
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/mk
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/src
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/src/include
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/src/catalog
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/src/catalog/include
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/MCAT
mkdir -p $RPM_BUILD_ROOT/%{srbroot}/data
cp -pr $RPM_BUILD_DIR/%{srbSrc}/utilities/bin/* $RPM_BUILD_ROOT%{_bindir}
cp -pr $RPM_BUILD_DIR/%{srbSrc}/utilities/admin-bin/* $RPM_BUILD_ROOT%{_bindir}
rm -rf $RPM_BUILD_ROOT%{_bindir}/{exitcode,getsrbobj,metaFile,metaFile2,metaFileManyData,CVS}
cp -pr $RPM_BUILD_DIR/%{srbSrc}/utilities/man/man1/*.1 $RPM_BUILD_ROOT%{_mandir}/man1
cp -p mk/RPM/srb $RPM_BUILD_ROOT/etc/rc.d/init.d
cp -pr mk/RPM/.srb $RPM_BUILD_ROOT/var/lib/srb
cp -pr $RPM_BUILD_DIR/%{srbSrc}/obj/*.a $RPM_BUILD_ROOT/%{srbroot}/obj
cp -pr $RPM_BUILD_DIR/%{srbSrc}/mk/mk.* $RPM_BUILD_ROOT/%{srbroot}/mk
cp -pr $RPM_BUILD_DIR/%{srbSrc}/MCAT/* $RPM_BUILD_ROOT/%{srbroot}/MCAT
cp -pr $RPM_BUILD_DIR/%{srbSrc}/data/* $RPM_BUILD_ROOT/%{srbroot}/data
cp -pr $RPM_BUILD_DIR/%{srbSrc}/src/include/* $RPM_BUILD_ROOT/%{srbroot}/src/include
cp -pr $RPM_BUILD_DIR/%{srbSrc}/src/catalog/include/* $RPM_BUILD_ROOT/%{srbroot}/src/catalog/include
# rm -rf $RPM_BUILD_ROOT/%{srbroot}/%{srbSrc}/inQ
# rm -rf $RPM_BUILD_ROOT/%{srbroot}/%{srbSrc}/mySRB

#find $RPM_BUILD_ROOT -name CVS -exec rm -rf {} \;
rm -rf $RPM_BUILD_ROOT/usr/srb/bin/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/bin/commands/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/bin/commands/examples/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/bin/commands/real/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/data/lockDir/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/data/log/CVS
rm -rf $RPM_BUILD_ROOT/usr/srb/data/CVS
rm -rf $RPM_BUILD_ROOT/var/lib/srb/.srb/CVS
rm -rf $RPM_BUILD_ROOT/%{srbroot}/MCAT/install.pl
rm -rf $RPM_BUILD_ROOT/%{srbroot}/MCAT/install.ora.pl

mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d/
echo '#!/bin/bash
#
# srb        Starts SRB Server
#
#
# chkconfig: 2345 99 01

# Source function library.
. /etc/init.d/functions

# Local Configuration Parameters
SRBUSER=srb
SRBHOME=/usr/srb
PGDATA=/var/lib/srb/mcat
PGLOG=/var/lib/srb/mcat.log

RETVAL=0
umask 077
[ -n "$NICELEVEL" ] && nice="nice -n $NICELEVEL"

start() {
       echo -n $"Starting postgres for SRB: "
       runuser -s /bin/bash - $SRBUSER -c "pg_ctl -D $PGDATA -l $PGLOG start"
       RETVAL=$?
       sleep 8
       if [ $RETVAL -eq 0 ]; then
         echo "SUCCESS STARTING POSTGRES"
       else
         echo "FAILED STARTING POSTGRES"
         return $RETVAL
       fi

       echo -n $"Starting SRB: "
       runuser -s /bin/bash - $SRBUSER -c "cd $SRBHOME/bin; ./runsrb"
       RETVAL=$?
       if [ $RETVAL -eq 0 ]; then
         echo "SUCCESS STARTING SRB"
       else
         echo "FAILED STARTING SRB"
       fi
       return $RETVAL
}
stop() {
       echo -n $"Stopping SRB: "
       runuser -s /bin/bash - $SRBUSER -c "cd $SRBHOME/bin; ./killsrb now"
       RETVAL=$?
       if [ $RETVAL -eq 0 ]; then
         echo "SUCCESS STOPPING SRB"
       else
         echo "FAILED STOPPING SRB"
         return $RETVAL
       fi
       echo -n $"Stopping postgres for SRB: "
       runuser -s /bin/bash - $SRBUSER -c "pg_ctl -D $PGDATA -l $PGLOG stop"
       RETVAL=$?
       if [ $RETVAL -eq 0 ]; then
         echo "SUCCESS STOPPING POSTGRES"
       else
         echo "FAILED STOPPING POSTGRES"
       fi
       return $RETVAL
}
mystatus() {
       status srbServer
}
restart() {
       stop
       start
}

case "$1" in
 start)
       start
       ;;
 stop)
       stop
       ;;
 status)
       mystatus
       ;;
 restart|reload)
       restart
       ;;
 *)
       echo $"Usage: $0 {start|stop|status|restart}"
       exit 1
esac

exit $?' > $RPM_BUILD_ROOT/etc/rc.d/init.d/srb

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%pre server
if ! getent passwd srb >/dev/null 2>&1 ; then
    /usr/sbin/useradd -m -d /var/lib/srb -s /bin/bash -c "SRB Server" srb > /dev/null 2>&1 || :
    echo "export LANG=en_US.iso88591" >> /var/lib/srb/.bashrc
    echo "export LANG=en_US.iso88591" >> /var/lib/srb/.profile
fi
if ! grep -q %{srbroot}/lib /etc/ld.so.conf; then
        echo "%{srbroot}/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

%post server
#rm -f /etc/rc.d/init.d/srb

#chmod a+x /etc/rc.d/init.d/srb
#if [ $1 = 1 ]; then
#    /sbin/chkconfig --add srb
#fi
#/bin/chmod 0755 /var/lib/srb
#/bin/chmod 0750 /var/lib/srb/.srb
#if [ $1 = 0 ]; then
#    /sbin/chkconfig --del srb
#fi

%preun server
if  rpm -qa | grep srb-install ; then
    su srb -s /bin/bash -mc "/usr/bin/pg_ctl -D %{srbHome}/mcat stop"
fi

%postun server
if [ $1 -ge 1 ]; then
    /sbin/service srb condrestart >/dev/null 2>&1 || :
fi
if [ $1 = 0 ] ; then
        userdel srb >/dev/null 2>&1 || :
fi

# %files gridftp-dsi-dependencies
# /%{srbroot}/%{srbSrc}/*


################### server config ##############################################
%pre install
rm -rf /etc/rc.d/init.d/srb

%post install

export HOSTNAME=`uname -n`
export HOST=`host $HOSTNAME | grep "has address"`
export HOSTIP=`echo $HOST | awk {'print $4'}`

if [[ !$PGPORT ]]; then
    export PGPORT=5432
fi

if [[ !$MCATDATA ]]; then
    export MCATDATA=%{srbHome}/mcat
fi

if [[ !$SRB_DOMAIN ]]; then
    export SRB_DOMAIN=$HOSTNAME
fi

if [[ !$SRB_ADMIN_NAME ]]; then
    export SRB_ADMIN_NAME=srbAdmin
fi

if [[ !$SRB_ADMIN_PASSWD ]]; then
    export SRB_ADMIN_PASSWD='adim#srb'
fi

if [[ !$SRB_VAULT ]]; then
    export SRB_VAULT=%{srbHome}/Vault
fi

if [[ !$SRB_LOCATION ]]; then
    export SRB_LOCATION=$HOSTNAME
fi

if [[ !$SRB_ZONE ]]; then
    export SRB_ZONE=$HOSTNAME
fi

if [[ !$SRB_RESOURCE ]]; then
    export SRB_RESOURCE=$HOSTNAME
fi

cat <<-EOF > %{srbroot}/data/MdasConfig
DASDBTYPE        postgres
MDASDBNAME        PostgreSQL
MDASINSERTSFILE  %{srbroot}/data/mdas_inserts
METADATA_FKREL_FILE metadata.fkrel
DB2USER           srb
DB2LOGFILE       %{srbroot}/data/db2logfile
DBHOME          $MCATDATA
EOF
/bin/chown srb:srb %{srbroot}/data/MdasConfig

cat <<-EOF > %{srbHome}/.odbc.ini
[PostgreSQL]
Driver=%{srbroot}/lib/psqlodbc.so
Debug=0
CommLog=0
Servername=$HOSTNAME
Database=MCAT
Username=srb
Port=$PGPORT
EOF
/bin/chown srb:srb %{srbHome}/.odbc.ini

su srb -s /bin/bash -mc "unset LANG && /usr/bin/initdb --lc-collate=C -D $MCATDATA"

su srb -s /bin/bash -mc "cp $MCATDATA/postgresql.conf $MCATDATA/postgresql.conf.old"
su srb -s /bin/bash -mc "sed s/#listen_addresses\ =\ \'localhost\'/listen_addresses\ =\ \'*\'/ $MCATDATA/postgresql.conf.old > $MCATDATA/postgresql.conf"
su srb -s /bin/bash -mc "cp $MCATDATA/postgresql.conf $MCATDATA/postgresql.conf.old"
su srb -s /bin/bash -mc "sed s/#port\ =\ 5432/port\ =\ $PGPORT/g $MCATDATA/postgresql.conf.old > $MCATDATA/postgresql.conf"

cat <<-EOF >> $MCATDATA/pg_hba.conf
host    all         all         $HOSTIP/32        trust
EOF

su srb -s /bin/bash -mc "/usr/bin/pg_ctl -D $MCATDATA start"
sleep 10 # to give postmaster time to start before the trying to create the database
su srb -s /bin/bash -mc "unset LANG && /usr/bin/createdb MCAT"

su srb -s /bin/bash -mc "cd %{srbroot}/MCAT/data && /usr/bin/psql MCAT < catalog.install.psg"

su srb -s /bin/bash -mc "export srbUser=srb && export srbAuth=CANDO && export mdasDomainName=sdsc && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && cd %{srbroot}/MCAT/bin && ./ingestToken Domain $SRB_DOMAIN gen-lvl4"
su srb -s /bin/bash -mc "export srbUser=srb && export srbAuth=CANDO && export mdasDomainName=sdsc && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && cd %{srbroot}/MCAT/bin && ./ingestUser $SRB_ADMIN_NAME '$SRB_ADMIN_PASSWD' $SRB_DOMAIN sysadmin '' '' '' "
su srb -s /bin/bash -mc "export srbUser=srb && export srbAuth=CANDO && export mdasDomainName=sdsc && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && cd %{srbroot}/MCAT/bin && ./modifyUser changePassword srb sdsc '$SRB_ADMIN_PASSWD' "

mkdir -p %{srbHome}/.srb
cat <<-EOF > %{srbHome}/.srb/.MdasEnv
mdasCollectionName '/$SRB_ZONE/home/$SRB_ADMIN_NAME.$SRB_DOMAIN'
mdasCollectionHome '/$SRB_ZONE/home/$SRB_ADMIN_NAME.$SRB_DOMAIN'
mdasDomainName '$SRB_DOMAIN'
mdasDomainHome '$SRB_DOMAIN'
srbUser '$SRB_ADMIN_NAME'
srbHost '$HOSTNAME'
#srbPort '5544'
defaultResource '$SRB_RESOURCE'
#AUTH_SCHEME 'PASSWD_AUTH'
#AUTH_SCHEME 'GSI_AUTH'
AUTH_SCHEME 'ENCRYPT1'
EOF

cat <<-EOF > %{srbHome}/.srb/.MdasAuth
$SRB_ADMIN_PASSWD
EOF

su srb -s /bin/bash -mc "cp %{srbroot}/data/mcatHost %{srbroot}/data/mcatHost.old"
su srb -s /bin/bash -mc "sed s/srb.sdsc.edu/$HOSTNAME/ %{srbroot}/data/mcatHost.old > %{srbroot}/data/mcatHost"

/bin/chown -R srb:srb %{srbHome}/.srb

su srb -c "cd %{srbroot}/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && ./runsrb"

su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && ./ingestLocation '$SRB_LOCATION' '$HOSTNAME:NULL.NULL' 'level4' $SRB_ADMIN_NAME $SRB_DOMAIN"

mkdir -p $SRB_VAULT
chown srb:srb $SRB_VAULT
su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && ./ingestResource '$SRB_RESOURCE' 'unix file system' '$SRB_LOCATION' '$SRB_VAULT/?USER.?DOMAIN/?SPLITPATH/?PATH?DATANAME.?RANDOM.?TIMESEC' permanent 0"

su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Sinit && /usr/bin/Szone -C demozone $SRB_ZONE && /usr/bin/Szone -C demozone $SRB_ZONE && /usr/bin/Sexit" # change zone twice; tipp from install.pl
#su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Sinit && /usr/bin/Szone -C demozone $SRB_ZONE && /usr/bin/Szone -C demozone $SRB_ZONE && /usr/bin/Sexit" # change zone twice; tipp from install.pl

# run twice as well
su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Sinit && /usr/bin/Szone -M $SRB_ZONE $SRB_LOCATION '' $SRB_ADMIN_NAME@$SRB_DOMAIN '' 'Zone create by install RPM' && /usr/bin/Sexit"
su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Sinit && /usr/bin/Szone -M $SRB_ZONE $SRB_LOCATION '' $SRB_ADMIN_NAME@$SRB_DOMAIN '' 'Zone create by install RPM' && /usr/bin/Sexit"

# create SDSC ticketuser -> broken in 3.5 as it doesn't exist by default but nothing works without it
su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Singestuser ticketuser ansdkjqw sdsc public '' '' '' ENCRYPT1 ''"

# Setup inca test user

if [[ !$SRB_INCA_DN ]]; then
    export SRB_INCA_DN='/C=AU/O=APACGrid/OU=SAPAC/CN=Gerson Galang GTest'
fi

if [[ !$SRB_NO_INCA ]]; then
    echo "Setting up INCA Test User."
    su srb -s /bin/bash -mc "export HOME=%{srbHome} && cd %{srbroot}/MCAT/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && /usr/bin/Sinit && /usr/bin/Singestuser inca GTest $SRB_DOMAIN  staff '' '' '' GSI_AUTH '/C=AU/O=APACGrid/OU=SAPAC/CN=Gerson Galang GTest' && /usr/bin/Sexit"

    if ! test -d /etc/grid-security; then
        mkdir etc/grid-security
    fi
    if ! test -e /etc/grid-security/grid-mapfile.srb; then
        touch /etc/grid-security/grid-mapfile.srb
    fi 

    if ! grep -q inca@$SRB_DOMAIN /etc/grid-security/grid-mapfile.srb; then
        echo "\"$SRB_INCA_DN\" inca@$SRB_DOMAIN" >> /etc/grid-security/grid-mapfile.srb
    fi
    echo "done."
fi
# done

cat<<EOF
--------------------------------------------------
If you see and error like:

Szone: Error in Performing Action: -1007
AUTH_ERR_PROXY_NOPRIV: proxy user not privileged

or

Szone: Error in Performing Action: -3314
ZONE_NAME_NOT_IN_CAT: ZONE_NAME_NOT_IN_CAT

it is most likely ok.
---------------------------------------------------
EOF

%files install
%attr(0755,root,root) /etc/rc.d/init.d/srb
################### end server config ##############################################

%pre server-update
su srb -c "cd %{srbroot}/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && ./killsrb now"
su srb -c "cd %{srbroot}/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && cp runsrb ../runsrb-3.4.2"
su srb -c "cd %{srbroot} && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && tar -cf bin-3.4.2.tar bin"

%post server-update
chown -R srb:srb %{srbroot}/bin
su srb -c "cd %{srbroot} && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && sed s/3.4.2/3.5.0/g runsrb-3.4.2 > bin/runsrb"
su srb -c "cd %{srbroot}/bin && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%{srbroot}/lib && ./runsrb"

%files server-update
%{srbroot}/bin/*

%files clients
%{_bindir}/*
%{_mandir}/man1/*

%files server
%defattr(-,srb,srb)
%doc COPYRIGHT
%{srbroot}/*
/etc/rc.d/init.d/srb
%attr(0755,srb,srb) %dir /var/lib/srb
%attr(0750,srb,srb) /var/lib/srb/.srb
%attr(0640,srb,srb) %config /var/lib/srb/.srb/.Mdas*

%changelog
* Wed May 14 2008 Florian Goessmann <florian@ivec.org>
- fixed problem caused when yum install was called from a c shell
* Tue May 06 2008 Florian Goessmann <florian@ivec.org>
- applied JCU patches for Shibboleth, thanks to Nigel Sim <nigel.sim@jcu.edu.au>
- disabled build of gridhttpd -> never worked and broke the build with the patches
* Fri Apr 18 2008 Florian Goessmann <florian@ivec.org>
- added creation of ticketuser
* Wed Apr 3  2008 Florian Goessmann <florian@ivec.org>
- fixed a problem with the creation of the init script
- enabled GridHTTPD
- fixed a problem with demozone not being correctly changed to new zone
* Mon Feb 11 2008 Florian Goessmann <florian@ivec.org>
- added changelog
- now depends on the SRB enabled package of gridFTP
- changed name of server-config to install

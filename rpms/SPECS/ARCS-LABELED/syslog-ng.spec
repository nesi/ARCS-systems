Summary:        syslog-ng
Name:           syslog-ng
Version:        2.0.8
Release:        1.arcs
License:        GPLv2
Group:          System/Application
Source:         %{name}-%{version}.tar.gz
Packager:       Florian Goessmann <florian@ivec.org>
Buildroot:      %{_tmppath}/%{name}-root
BuildPreReq:    make gcc eventlog >= 0.2.7
Requires:	eventlog >= 0.2.7

%description
http://www.campin.net/syslog-ng/syslog.html

%prep
%setup -q

%build
./configure --prefix=%{buildroot}/usr/local
make

%install
make install

mkdir -p %{buildroot}/etc/rc.d/init.d
cat <<EOF > %{buildroot}/etc/rc.d/init.d/syslog-ng
#!/bin/bash

#
#description: syslog-ng starup script
#
#process name: syslog-ng
#config: /etc/syslog-ng/syslog-ng.conf
#pidfile: /var/run/syslog-ng.pid

#source function library
. /etc/rc.d/init.d/functions

RETVAL=0

 case "$1" in
         start)
                 echo -n "Starting syslog-ng: "
                 if [ ! -f /var/run/syslog-ng.pid ] ; then
                         case "`type -type success`" in
                           function)
                           /usr/local/sbin/syslog-ng -f /etc/syslog-ng.conf && success "syslog-ng startup" || \
                                failure "syslog-ng startup"
                            RETVAL=$?
                          ;;
                          *)
                           /usr/local/sbin/syslog-ng && echo -n "syslog-ng "
                            RETVAL=$?
                          ;;
                          esac
                          [ $RETVAL -eq 0 ] && echo -n "syslog-ng "
                 fi
                 echo
                 ;;
         stop)
                 echo -n "Shutting down syslog-ng; "
                 if [ -f /var/run/syslog-ng.pid ] ; then
                         killproc syslog-ng
                 fi
                 echo
                 [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/syslog-ng
                 ;;
         restart)
                 $0 stop
                 $0 start
                 RETVAL=$?
                 ;;
         status)
                 status syslog-ng
                 RETVAL=$?
                 ;;
         *)
                 echo "Usage: {start|stop|restart|status}"
                 exit 1
 esac
EOF

chmod a+x %{buildroot}/etc/rc.d/init.d/syslog-ng

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/*
/etc/rc.d/init.d/syslog-ng

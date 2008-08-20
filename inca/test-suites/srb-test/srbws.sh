#!/bin/sh
. /etc/profile.d/vdt_setup.sh
export http_proxy=http://www-proxy.sapac.edu.au:8080
cd /home/inca/srb-test
/opt/vdt/vdt/bin/perl /home/inca/srb-test/srbws.pl > /tmp/srbws-test.log

#!/bin/sh
. /etc/profile.d/vdt_setup.sh
cd /home/inca/srb-test
/opt/vdt/vdt/bin/perl /home/inca/srb-test/srbws.pl > /tmp/srbws-test.log

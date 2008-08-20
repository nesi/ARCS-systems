#!/bin/sh
. /etc/profile.d/vdt_setup.sh
/opt/vdt/vdt/bin/perl /home/inca/srb-test/srbws.pl > /tmp/srbws-test.log

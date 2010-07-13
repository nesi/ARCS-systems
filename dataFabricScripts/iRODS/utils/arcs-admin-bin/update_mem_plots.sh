#!/bin/bash
# $Id$
# $HeadURL$
day=$(date +%a)
cat /tmp/record_usage.sh.$day | /Home/arcs-admin/bin/record2gp.sh > /tmp/$day.gp
gnuplot /tmp/$day.gp > /tmp/$day.png
perl -pi -e 's/png/svg size 800 600 fsize 10/' /tmp/$day.gp
gnuplot /tmp/$day.gp | sed 'sXxmlns:xlinkXxmlns="http://www.w3.org/2000/svg" xmlns:xlinkX' > /tmp/$day.svg
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/itrim /ARCS/home/ARCS-DATA/server_mem/$day.png
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/itrim /ARCS/home/ARCS-DATA/server_mem/$day.svg
env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/iput -f /tmp/$day.png /ARCS/home/ARCS-DATA/server_mem/
env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/iput -f /tmp/$day.svg /ARCS/home/ARCS-DATA/server_mem/
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/irepl -U /ARCS/home/ARCS-DATA/server_mem/$day.png
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/irepl -U /ARCS/home/ARCS-DATA/server_mem/$day.svg


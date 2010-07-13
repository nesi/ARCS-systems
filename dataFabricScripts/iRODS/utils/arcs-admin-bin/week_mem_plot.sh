#!/bin/bash
# $Id$
# $HeadURL$
cat /tmp/record_usage.sh.* | /Home/arcs-admin/bin/record2gp.sh > /tmp/week.gp
perl -pi -e 's/set key outside/set key off/; s/%H:%M/%m-%d/; s/60\*60\*4/60*60*24/' /tmp/week.gp
gnuplot /tmp/week.gp > /tmp/week.png
perl -pi -e 's/png/svg size 800 600 fsize 10/' /tmp/week.gp
gnuplot /tmp/week.gp | sed 'sXxmlns:xlinkXxmlns="http://www.w3.org/2000/svg" xmlns:xlinkX' > /tmp/week.svg
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/itrim /ARCS/home/ARCS-DATA/server_mem/week.png
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/itrim /ARCS/home/ARCS-DATA/server_mem/week.svg
env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/iput -f /tmp/week.png /ARCS/home/ARCS-DATA/server_mem/
env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/iput -f /tmp/week.svg /ARCS/home/ARCS-DATA/server_mem/
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/irepl -U /ARCS/home/ARCS-DATA/server_mem/week.png
#env LD_LIBRARY_PATH=/opt/vdt/globus/lib /opt/iRODS/iRODS/clients/icommands/bin/irepl -U /ARCS/home/ARCS-DATA/server_mem/week.svg


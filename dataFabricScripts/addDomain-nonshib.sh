#!/bin/sh
# Ingests the domain passed in

echo $* >> /tmp/adddomain

. /opt/srb/admin-setup.sh
ingestToken Domain $1 gen-lvl4 | grep -v '\-3119'


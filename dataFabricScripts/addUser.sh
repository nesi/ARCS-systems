#!/bin/bash
# Ingests the user in it's raw state

echo $1 $2 $3 >> /tmp/adduser
export LD_LIBRARY_PATH=/user/srb/globus/lib
export PATH=$PATH:/usr/srb/MCAT/bin
ingestUser $1 '' $2 staff '' '' '' 
modifyUser insertAuthMap $1 $2 "GSI_AUTH:$3"


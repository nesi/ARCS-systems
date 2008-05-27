#!/bin/sh
# calls Srsync to make sure that an SRB server has a replica of a local directory
#  structure

# specify the local directory to synchronise with the SRB server
localdir=/Users/sjm900/tmp

# specify the SRB directory
srbdir=/srb.dc.apac.edu.au/home/sjm900.srb.dc.apac.edu.au/synctest

# initialise SRB.  Assumes the account information is correctly set up.
Sinit -v

# synchronise
#  -M: client initiated parallel transfer
#  -r: recurse
#  -v: verbose
Srsync -Mrv ${localdir} s:${srbdir}

# finish the SRB session
Sexit

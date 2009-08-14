#!/bin/sh

vaultDir=<PATH TO VAULT DIR>
tree="ARCS projects IMOS"
user=<USERNAME OF TDS USER>

for dir in $tree
do
    cd $vaultDir
    setfacl -m u:$user:--x $dir
    vaultDir=$dir
done

cd IMOS
setfacl -m u:$user:r-x -m m::r-x opendap
setfacl -d -m u:$user:r-x -m m::r-x opendap

cd opendap
find -type f -exec setfacl -m u:$user:r-- -m m::r-- {} \;
find -type d -exec setfacl -m u:$user:r-x -m m::r-x {} \;
find -type d -exec setfacl -d -m u:$user:r-x -m m::r-x {} \;


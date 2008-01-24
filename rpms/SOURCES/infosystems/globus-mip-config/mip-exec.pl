#!/usr/bin/perl
@output=`/usr/local/mip/mip glue`;
foreach (@output) {
  if (/Site UniqueID=/) {
    s|>| xmlns="http://forge.cnaf.infn.it/glueschema/Spec/V12/R2" xmlns:apac="http://grid.apac.edu.au/glueschema/Spec/V12/R1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" >|;
  }
  elsif (/SubCluster UniqueID=/) {
    s/>/ xsi:type="apac:APACSubClusterType" >/;
  }
  elsif (/SoftwarePackage LocalID=/) {
    s|>| xmlns="http://grid.apac.edu.au/glueschema/Spec/V12/R1" >|;
  }
  print $_;
}


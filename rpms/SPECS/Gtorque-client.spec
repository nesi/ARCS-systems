Summary:	The Portable Batch System (PBS) Client
Name:		Gtorque-client
Version:	2.1.8
Release:	3
License:	PBS
Group:		Cluster/Queueing Services
BuildRoot:	/home/graham/rpmbuild/redhat/BUILD/%{name}-buildroot
ExclusiveArch:	i386 x86_64
Requires: 	ntp sed ed bash

%description
The Portable Batch System (PBS) Client is a workload management
system originally developed at the NASA Ames Research Center.

%install
%files
%defattr(-,root,root)
/

%post
chmod u+s /usr/local/sbin/pbs_iff
ln -s  /usr/spool/PBS /usr/spool/pbs || :
echo "You will need to edit: /usr/spool/PBS/server_name"

%define		_use_internal_dependency_generator 0

Summary:	PBS Log Replicator
Name:		pbs-telltail
Version:	1.0.2
Release:	8
License:	GNU
Group:		Cluster/Queueing Services
BuildRoot:	/home/graham/rpmbuild/redhat/BUILD/%{name}-buildroot
BuildArch:	noarch
Requires: 	perl

%description
The PBS Log Replicator replicates logs from cluster management
nodes so that they can be accessed using the Globus Toolkit.

%install
%files
%defattr(-,root,root)
/

%post
mkdir -p /usr/spool/pbs/server_logs
chkconfig pbs-logmaker on
service pbs-logmaker start

%preun
service pbs-logmaker stop || :
chkconfig --del pbs-logmaker

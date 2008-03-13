#
# vim:nohls syntax=none ts=4
#
# make MIP configuration files for APAC National Grid
#
# 2008-13-03, v1.3, Gerson Galang, gerson.galang@sapac.edu.au
#             modified to conform with latest changes to the
#             MIP and apac mip module
#
# 2007-05-09, v1.2, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             unnecessary lines cleanup as William Hsu recommended
#
# 2007-05-08, v1.1, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             subcluster with its own qfdn
#
# 2007-05-08, v1.0, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             this file should be "/usr/local/mip/lib/APAC/mipconfig.pm"
#
# 2007-05-07, v0.6, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             backup original config files before updating
#             changed apacvo from data.<VONAME> to <VONAME>.vo
#             as Gerson Galang recommended
#
# 2007-05-06, v0.5, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             all optional entries for subcluster
#             queue specific VO support
#
# 2007-05-05, v0.4, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             code update with hash references
#
# 2007-05-04, v0.3, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             multiple {cluster, storage, acl}
#
# 2007-05-03, v0.2, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             multiple cluster, single {storage,acl}
#
# 2007-05-02, v0.1, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             single cluster
#
package APAC::mipconfig;

use strict;
use warnings;

BEGIN
{
        use Exporter ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

        # set the version for version checking
        $VERSION = 1.00;

        # if using RCS/CVS, this may be preferred
        $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;

        @ISA         = qw(Exporter);
        @EXPORT      = qw(
                %site_info
                %vo_info
                %storage_info
                %cluster_info
                %gateway_info
				&make_apac_mipconfig);
        %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

        # your exported package globals go here,
        # as well as any optionally exported functions
        @EXPORT_OK   = qw(&last_month_days &is_weekday);
}
our @EXPORT_OK;

# exported package globals go here
our %site_info;
our %vo_info;
our %storage_info;
our %cluster_info;
our %gateway_info;

# non-exported package globals go here

# initialize package globals, first exported ones
%site_info = ();
%vo_info = ();
%storage_info = ();
%cluster_info = ();
%gateway_info = ();

############################################################
# site specific data area
############################################################

# you will need to change in the following sections
# Sec 1: SiteInfo - replace almost all values
# Sec 2: Storage  - may need to comment out 'gsiftp2' part (ref in Sec.4)
# Sec 3: APACVO   - definition only (referred in Sec 4)
# Sec 4: Cluster  - all clusters, minimum change list
#                   'disabled' => publish to MDS or not
#                   'name'     => short hostname of your cluster
#                   'fqdn'     => long hostname of your cluster
#                   'storage'  => entry defined in Sec.2
#                   'sub1'     => all entries about your HW and OS
# Sec 5: Gateway  - about gateway machine (default should be fine)

#ac3#
#ac3# Section 1: Site Info (EDIT this section!)
#ac3############################################################
#ac3chomp($site_domain = `hostname -d`);
#ac3
#ac3%site_info = (
#ac3	'name'        => "ac3",
#ac3	'description' => "ac3",
#ac3	'location'    => "Sydney",
#ac3	'latitude'    => '-33.89516',
#ac3	'longitude'   => '151.19556',
#ac3	'weburl'      => 'http://www.ac3.edu.au',
#ac3	'contact'     => 'ngadmin@ac3.edu.au',
#ac3	'domain'      => $site_domain,
#ac3# overwrite it as required
#ac3#	'domain'      => 'apac3.edu.au',
#ac3);
#ac3
#ac3#
#ac3##
#ac3## Section 2: Site Storage Info (list of StorageElement)
#ac3#############################################################
#ac3#%storage_info  = (
#ac3#	'ngdata.' . $site_domain => {
#ac3#		'gsiftp1' => {
#ac3#			gridftp_server => 'ngdata.' . $site_domain,
#ac3#			gridftp_version => '2.3',
#ac3#		},
#ac3#
#ac3## comment out 'gsiftp2' block if you don't have gridftp on ng2
#ac3#		'gsiftp2' => {
#ac3#			gridftp_server => 'ng2.' . $site_domain,
#ac3#			gridftp_version => '2.3',
#ac3#		},
#ac3##
#ac3#	},
#ac3#);
#ac3#
#ac3##
#ac3## Section 3: APAC VO Info
#ac3#############################################################
#ac3#%vo_info = (
#ac3#
#ac3#	'/APACGrid/GTest' => {
#ac3#		'luid' => 'grid.test.vo',
#ac3#		'user' => 'grid-test',
#ac3#		'datadir' => '/data/grid/grid-test'
#ac3#	},
#ac3#
#ac3#	'/APACGrid/NGAdmin' => {
#ac3#		'luid' => 'grid.admin.vo',
#ac3#		'user' => 'grid-admin',
#ac3#		'datadir' => '/data/grid/grid-admin'
#ac3#	},
#ac3#
#ac3#	'/APACGrid/OceanModels' => {
#ac3#		'luid' => 'grid.ocean.vo',
#ac3#		'user' => 'grid-ocean',
#ac3#		'datadir' => '/data/grid/grid-ocean'
#ac3#	},
#ac3#);
#ac3#
#ac3##
#ac3## Section 4: Cluster Info (Everything about your clusters and queues)
#ac3#############################################################
#ac3#%cluster_info = (
#ac3#
#ac3## first cluster ( has to be named 'default' )
#ac3#	'default' => {
#ac3#		'disabled' => '0',
#ac3#
#ac3#		'name' => 'barossa',
#ac3#		'fqdn' => 'barossa.' . $site_domain,
#ac3#		'systmp' => '/tmp',
#ac3#		'usrtmp' => '~/.globus/scratch',
#ac3#		'storage' => 'ngdata.' . $site_domain,
#ac3#
#ac3#		'subclusters' => {
#ac3#
#ac3#			'sub1' => {
#ac3#
#ac3#				'PlatformType' => '',
#ac3#				'SMPSize' => 1,
#ac3#				'PhysicalCPUs' => 304,
#ac3#				'LogicalCPUs'  => 304,
#ac3#				'MainMemory.RAMSize'  => 2048,
#ac3#				'MainMemory.VirtualSize'  => 4096,
#ac3#
#ac3#				'optional' => {
#ac3#				'Processor.Model' => 'Intel(R) Xeon(TM) CPU 3.06GHz',
#ac3#				'Processor.Vendor' => 'GenuineIntel',
#ac3#				'Processor.ClockSpeed' => '3056',
#ac3#				'Processor.InstructionSet' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm',
#ac3#				'OperatingSystem.Name' => 'RedHat Linux',
#ac3#				'OperatingSystem.Release' => '7.3',
#ac3#				'OperatingSystem.Version' => '7.3'
#ac3#				},
#ac3#			},
#ac3#
#ac3##			'sub2' => {
#ac3##				'PhysicalCPUs' => 304,
#ac3##				'LogicalCPUs'  => 304,
#ac3##				'MainMemory.RAMSize'  => 2048,
#ac3##				'MainMemory.VirtualSize'  => 4096,
#ac3##			},
#ac3#
#ac3#		},
#ac3#
#ac3#		'queue_system_type' => 'Torque',
#ac3#		'default_vos' => [
#ac3#					'/APACGrid/GTest',
#ac3#					'/APACGrid/NGAdmin',
#ac3#					'/APACGrid/OceanModels',
#ac3#				],
#ac3#		'queues'     => {
#ac3#			'express' => { },
#ac3#			'short' => { },
#ac3#			'checkable' => { },
#ac3#			'single' => { },
#ac3#			'workq' => {
#ac3#				'vos' => [ '/APACGrid/OceanModels' ],
#ac3#			},
#ac3#		},
#ac3#	},
#ac3#
#ac3## second cluster
#ac3#
#ac3#	'second' => {
#ac3#		'disabled' => '0',
#ac3#
#ac3#		'name' => 'swan',
#ac3#		'fqdn' => 'swan.' . $site_domain,
#ac3#		'systmp' => '/tmp',
#ac3#		'usrtmp' => '~/.globus/scratch',
#ac3#		'storage' => 'ngdata.' . $site_domain,
#ac3#
#ac3#		'subclusters' => {
#ac3#
#ac3#			'sub1' => {
#ac3#				'PlatformType' => '',
#ac3#				'SMPSize' => 1,
#ac3#				'PhysicalCPUs' => 16,
#ac3#				'LogicalCPUs'  => 16,
#ac3#				'MainMemory_RAMSize'  => 32768,
#ac3#				'MainMemory_VirtualSize'  => 25853,
#ac3#
#ac3#				'optional' => {
#ac3#				'Processor.Model' => 'Itanium 2',
#ac3#				'Processor.Vendor' => 'GenuineIntel',
#ac3#				'Processor.ClockSpeed' => '1300',
#ac3#				'Processor.InstructionSet' => '',
#ac3#				'OperatingSystem.Name' => 'Red Hat Enterprise Linux',
#ac3#				'OperatingSystem.Release' => 'AS',
#ac3#				'OperatingSystem.Version' => '3'
#ac3#				},
#ac3#			},
#ac3#
#ac3##			'sub2' => {
#ac3##				'PhysicalCPUs' => 16,
#ac3##				'LogicalCPUs'  => 16,
#ac3##				'MainMemory_RAMSize'  => 32768,
#ac3##				'MainMemory_VirtualSize'  => 25853,
#ac3##			},
#ac3#
#ac3#		},
#ac3#
#ac3#		'queue_system_type' => 'Torque',
#ac3#		'default_vos' => [
#ac3#					'/APACGrid/GTest',
#ac3#					'/APACGrid/NGAdmin',
#ac3#					'/APACGrid/OceanModels',
#ac3#				],
#ac3#		'queues'     => {
#ac3#			'express' => { },
#ac3#			'short' => { },
#ac3#			'checkable' => { },
#ac3#			'single' => { },
#ac3#		},
#ac3#	},
#ac3#
#ac3## third cluster
#ac3#
#ac3#	'third' => {
#ac3#		'disabled' => '1',
#ac3#
#ac3#		'name' => 'gramps',
#ac3#		'fqdn' => 'gramps.' . $site_domain,
#ac3#		'systmp' => '/tmp',
#ac3#		'usrtmp' => '~/.globus/scratch',
#ac3##		'storage' => '',
#ac3#
#ac3#		'subclusters' => {
#ac3#
#ac3#			'sub1' => {
#ac3#				'PlatformType' => '',
#ac3#				'SMPSize' => 1,
#ac3#				'PhysicalCPUs' => 2,
#ac3#				'LogicalCPUs'  => 2,
#ac3#				'MainMemory.RAMSize'  => 512,
#ac3#				'MainMemory.VirtualSize'  => 512,
#ac3#
#ac3#				'optional' => {
#ac3#				'Processor.Model' => 'Intel(R) Pentium(R) III CPU',
#ac3#				'Processor.Vendor' => 'GenuineIntel',
#ac3#				'Processor.ClockSpeed' => '1263',
#ac3#				'Processor.InstructionSet' => 'fpu vme de pse tsc msr pae mce cx8 apic mtrr pge mca cmov pat pse36 mmx fxsr sse',
#ac3#				'OperatingSystem.Name' => 'RedHat Linux',
#ac3#				'OperatingSystem.Release' => 'Fedora Core',
#ac3#				'OperatingSystem.Version' => '2'
#ac3#				},
#ac3#			},
#ac3#
#ac3##			'sub2' => {
#ac3##				'PhysicalCPUs' => 2,
#ac3##				'LogicalCPUs'  => 2,
#ac3##				'MainMemory.RAMSize'  => 512,
#ac3##				'MainMemory.VirtualSize'  => 512,
#ac3##			},
#ac3#
#ac3#		},
#ac3#
#ac3#		'queue_system_type' => 'Torque',
#ac3#		'default_vos' => [
#ac3#					'/APACGrid/GTest',
#ac3#					'/APACGrid/NGAdmin',
#ac3#				],
#ac3#		'queues'     => {
#ac3#			'express' => { },
#ac3#			'workq' => { },
#ac3#		},
#ac3#	},
#ac3#);
#ac3#
#ac3##
#ac3## Section 5: Gateway Info (edit it for non-std install)
#ac3#############################################################
#ac3#chomp($gateway_hostname = `hostname -f`);
#ac3#%gateway_info = (
#ac3#	'fqdn' => $gateway_hostname,
#ac3#	# 'fqdn'    => 'ng2.' . $site_domain;
#ac3#	'qstat'     => '/usr/local/bin/qstat',
#ac3#	'pbsnodes'  => '/usr/local/bin/pbsnodes',
#ac3#);


############################################################
# nothing to change below this line
############################################################

# create file source.pl
sub make_source_pl()
{
	open(FH, ">/tmp/source.pl") or return("Error create source.pl\n");

	printf STDERR ("creating file /tmp/source.pl\n");
	printf IFH ("# check and backup /usr/local/mip/config/source.pl\n");
	printf IFH ("[ -f /usr/local/mip/config/source.pl ] && \\\n");
	printf IFH (" cp -p /usr/local/mip/config/source.pl \\\n");
	printf IFH (" /usr/local/mip/config/source.pl-backup\n");
	printf IFH ("cp /tmp/source.pl /usr/local/mip/config/\n\n");

	printf FH ("# These directories are created by install_mip\n");
	printf FH ("\n");
	printf FH ("mipdir => '/usr/local/mip',\n");
	printf FH ("moduledir => '/usr/local/mip/modules',\n");
	printf FH ("configdir => '/usr/local/mip/config',\n");
	printf FH ("\n");
	printf FH ("# Packages are ordered in terms of priority\n");
	printf FH ("#     left - lowest priority\n");
	printf FH ("#     right - highest priority\n");
	printf FH ("pkgs => [");

	my($cluster);

	foreach $cluster (sort keys %cluster_info)
	{
		if ( ! defined ($cluster_info{$cluster}{'disabled'}) ||
			$cluster_info{$cluster}{'disabled'} < 1 )
		{
			printf FH ("'%s',", $cluster);
		}
	}

	printf FH ("],\n");
	printf FH ("\n");
	printf FH ("# Default producer to use\n");
	printf FH ("producer => 'glue',\n");

	close(FH);
}

# create file default.pl
sub make_cluster_config_pl()
{
	my($cluster);
	my($cluster_count) = 0;

	foreach $cluster (sort keys %cluster_info)
	{
		my($clusref) = $cluster_info{$cluster};

		if ( ! defined($clusref->{'disabled'}) || $clusref->{'disabled'} < 1)
		{
			open(FH, ">/tmp/$cluster.pl")
				or return("Error create $cluster.pl\n");
			printf STDERR ("creating file /tmp/$cluster.pl\n");
			printf IFH ("# check and backup /usr/local/mip/config/$cluster.pl\n");
			printf IFH ("[ -f /usr/local/mip/config/$cluster.pl ] && \\\n");
			printf IFH (" cp -p /usr/local/mip/config/$cluster.pl \\\n");
			printf IFH (" /usr/local/mip/config/$cluster.pl-backup\n");
			printf IFH ("cp /tmp/$cluster.pl /usr/local/mip/config/\n\n");
			if ( ! -l "/usr/local/mip/modules/$cluster" )
			{
			printf IFH ("cd /usr/local/mip/modules; ln -s apac_py $cluster\n");
			}

			printf FH ("clusterlist => ['%s'],\n", $cluster);

			printf FH ("uids => {\n");
			if ( ! $cluster_count )
			{
			printf FH ("\tSite => [ \"%s\", ],\n", $site_info{'domain'});
			}
			$cluster_count++;

			printf FH ("\tCluster => [ \"%s\", ],\n", $clusref->{'fqdn'});

			printf FH ("\tComputingElement => [\n");

			my($q);

			foreach $q (keys %{$clusref->{'queues'}})
			{
				printf FH ("\t\t\"%s.%s\",\n", $q, $clusref->{'fqdn'});
			}

			printf FH ("\t\t],\n");

			my($subclusters) = $clusref->{'subclusters'};

			printf FH ("\tSubCluster => [ ");
			my($subcluster);
			foreach $subcluster (keys %{$subclusters})
			{
				my($subcluster_name) = $subcluster;
				if ( $subcluster_name !~ /\./ )
				{
					$subcluster_name = $subcluster . "." . $clusref->{'fqdn'};
				}

				printf FH ("\"%s\", ", $subcluster_name);
				if ( ! -e "/usr/local/mip/config/$cluster" . "_"
					. $subcluster_name . "_SIP.ini" )
				{
					printf IFH ("cp %s %s\n",
						"/usr/local/mip/config/default_sub1_SIP.ini",
						"/usr/local/mip/config/$cluster" . "_"
						. $subcluster_name . "_SIP.ini" );
				}
			}
			printf FH ("],\n");

			if ( defined($clusref->{'storage'}) )
			{
			printf FH ("\tStorageElement => [ \"%s\", ],\n",
				$clusref->{'storage'});
			}
			printf FH ("}\n");
			close(FH);
		}
	}
}

# create file apac_config.py
sub make_apac_config_py()
{
	open(FH, ">/tmp/apac_config.py")
		or return("Error create apac_config.py\n");

	printf STDERR ("creating file /tmp/apac_config.py\n");
	printf IFH ("# check and backup /usr/local/mip/config/apac_config.py\n");
	printf IFH ("[ -f /usr/local/mip/config/apac_config.py ] && \\\n");
	printf IFH (" cp -p /usr/local/mip/config/apac_config.py \\\n");
	printf IFH (" /usr/local/mip/config/apac_config.py-backup\n");
	printf IFH ("cp /tmp/apac_config.py /usr/local/mip/config/\n\n");

	printf FH ("package = config['default'] = Package()\n");
	printf FH ("\n");

	printf FH ("site = package.Site['%s'] = Site()\n", $site_info{'domain'});
	printf FH ("\n");
 
	printf FH ("site.Name = '%s'\n", $site_info{'name'});
	printf FH ("site.Description = '%s'\n", $site_info{'description'});
	printf FH ("site.OtherInfo = ['%s', 'Australia']\n", $site_info{'location'});
	printf FH ("site.Web = '%s'\n", $site_info{'weburl'});
	printf FH ("site.Sponsor = [ '%s' ]\n", $site_info{'name'});
	printf FH ("site.Location = '%s, Australia'\n", $site_info{'location'});
	printf FH ("site.Latitude = '%.5f'\n", $site_info{'latitude'});
	printf FH ("site.Longitude = '%.5f'\n", $site_info{'longitude'});
	printf FH ("site.Contact = 'mailto:%s'\n", $site_info{'contact'});
	printf FH ("\n");

	my($cluster);
	my($cluster_count) = 0;

	foreach $cluster (sort keys %cluster_info)
	{
		my($clusref) = $cluster_info{$cluster};

		if ( ! defined($clusref->{'disabled'}) || $clusref->{'disabled'} < 1)
		{
			my($cluster_fqdn) = $clusref->{'fqdn'};

			if ($cluster_count)
			{
				printf FH ("package = config['%s'] = Package()\n", $cluster);
			}
			$cluster_count++;

			printf FH ("cluster = package.Cluster['%s'] = Cluster()\n",
				$cluster_fqdn);
			printf FH ("\n");
 
			printf FH ("cluster.Name = '%s'\n", $cluster_fqdn);
			printf FH ("cluster.WNTmpDir = '%s'\n", $clusref->{'systmp'});
			printf FH ("cluster.TmpDir = '%s'\n", $clusref->{'usrtmp'});
			printf FH ("\n");

			my($q);

			foreach $q (sort keys %{$clusref->{'queues'}})
			{
				printf FH ("computeElement = package.ComputingElement['%s.%s'] = ComputingElement()\n",
					$q, $cluster_fqdn);
				printf FH ("\n");

				printf FH ("computeElement.Name = '%s@%s'\n",
					$q, $clusref->{'name'});
				printf FH ("computeElement.Status = 'Production'\n");
				printf FH ("computeElement.JobManager = '%s'\n",
					$clusref->{'job_manager'});
				printf FH ("computeElement.HostName = '%s'\n", $cluster_fqdn);
				printf FH ("computeElement.GateKeeperPort = 8443\n");
				printf FH ("computeElement.ContactString = 'https://%s:8443/wsrf/services/ManagedJobFactoryService'\n",
					$gateway_info{'fqdn'});
				if ( defined($clusref->{'storage'}))
				{
					printf FH ("computeElement.DefaultSE = '%s'\n",
						 $clusref->{'storage'});
				}
				printf FH ("computeElement.ApplicationDir = 'UNAVAILABLE'\n");
				printf FH ("computeElement.DataDir = cluster.TmpDir\n");
				printf FH ("computeElement.LRMSType = '%s'\n",
					$clusref->{'queue_system_type'});
				printf FH ("computeElement.qstat = '%s'\n", $gateway_info{'qstat'});
				printf FH ("computeElement.pbsnodes = '%s'\n",
					$gateway_info{'pbsnodes'});
				printf FH ("computeElement.GRAMVersion = '%s'\n", $gateway_info{'globus_version'});
				printf FH ("\n");

				if ( defined($clusref->{'queues'}{$q}{'vos'}) ||
					defined($clusref->{'default_vos'}) )
				{
					my($vos) = $clusref->{'default_vos'};

					if ( defined($clusref->{'queues'}{$q}{'vos'}))
					{
						$vos = $clusref->{'queues'}{$q}{'vos'};
					}

					my($vo);

					foreach $vo (@{$vos})
					{
						printf FH ("config['%s'].ComputingElement['%s.%s'].views['%s'] = VOView()\n",
							$cluster, $q, $cluster_fqdn, $vo_info{$vo}{'luid'});

						printf FH ("config['%s'].ComputingElement['%s.%s'].views['%s'].RealUser = '%s'\n",
							$cluster, $q, $cluster_fqdn, $vo_info{$vo}{'luid'},
							$vo_info{$vo}{'user'});
			
						if ( defined($clusref->{'storage'}) )
						{
							printf FH ("config['%s'].ComputingElement['%s.%s'].views['%s'].DefaultSE = '%s'\n",
								$cluster, $q, $cluster_fqdn, $vo_info{$vo}{'luid'},
								$clusref->{'storage'});
						}

						printf FH ("config['%s'].ComputingElement['%s.%s'].views['%s'].DataDir = '%s'\n",
							$cluster, $q, $cluster_fqdn, $vo_info{$vo}{'luid'},
							$vo_info{$vo}{'datadir'});

						printf FH ("config['%s'].ComputingElement['%s.%s'].views['%s'].ACL = [ '%s' ]\n",
							$cluster, $q, $cluster_fqdn, $vo_info{$vo}{'luid'},
							$vo);

						printf FH ("\n");
					}
				} #/vos
			} #/foreach queue

			my($subcluster);

			foreach $subcluster (sort keys %{$clusref->{'subclusters'}})
			{
				my($subclusref) = $clusref->{'subclusters'}{$subcluster};

				my($subcluster_name) = $subcluster;
				if ( $subcluster_name !~ /\./ )
				{
					$subcluster_name = $subcluster . "." . $cluster_fqdn;
				}

				printf FH ("subcluster = package.SubCluster['%s'] = SubCluster()\n",
					$subcluster_name);
				printf FH ("\n");
 
				printf FH ("subcluster.InboundIP = False\n");
				printf FH ("subcluster.OutboundIP = True\n");
				printf FH ("subcluster.PlatformType = '%s'\n",
					$subclusref->{'PlatformType'});
				printf FH ("subcluster.SMPSize = %d\n",
					$subclusref->{'SMPSize'});
				printf FH ("subcluster.PhysicalCPUs = %d\n",
					$subclusref->{'PhysicalCPUs'});
				printf FH ("subcluster.LogicalCPUs = %d\n",
					$subclusref->{'LogicalCPUs'});
				printf FH ("subcluster.WNTmpDir = cluster.WNTmpDir\n");
				printf FH ("subcluster.TmpDir = cluster.TmpDir\n");
				printf FH ("subcluster.Processor = Processor()\n");
				printf FH ("# subcluster.Processor.File = '/proc/cpuinfo'\n");
				printf FH ("subcluster.MainMemory = MainMemory()\n");
				printf FH ("# subcluster.MainMemory.File = '/proc/meminfo'\n");
				printf FH ("subcluster.MainMemory.RAMSize = '%d'\n",
					$subclusref->{'MainMemory.RAMSize'});
				printf FH ("subcluster.MainMemory.VirtualSize = '%d'\n",
					$subclusref->{'MainMemory.VirtualSize'});
				printf FH ("subcluster.OperatingSystem = OperatingSystem()\n");
				printf FH ("# subcluster.OperatingSystem.File = '/usr/bin/lsb_release'\n");

				if ( defined($subclusref->{'optional'}))
				{
					my($optref) = $subclusref->{'optional'};
					my($k);
					foreach $k (sort keys %{$optref})
					{
						printf FH ("subcluster.%s = '%s'\n", $k, $optref->{$k});
					}
				}
				printf FH ("\n");
			} #/foreach subcluster
		} #/active cluster

		if ( (! defined($clusref->{'disabled'}) || $clusref->{'disabled'} < 1) && defined($clusref->{'storage'}) )
		{
			printf FH ("storageElement = package.StorageElement['%s'] = StorageElement()\n",
				$clusref->{'storage'});
			printf FH ("storageElement.RootDirectory = '%s'\n", 
				$storage_info{$clusref->{'storage'}}{'root_directory'});

			printf FH ("storageElement.Architecture = '%s'\n", 
				$storage_info{$clusref->{'storage'}}{'architecture'});
			printf FH ("\n");
			my($vo);
			foreach $vo (sort keys %vo_info)
			{
				printf FH ("area = storageElement.areas['%s'] = StorageArea()\n",
						$vo_info{$vo}{'luid'});
				printf FH ("\n");
 
				printf FH ("area.Path = '%s'\n", $vo_info{$vo}{'datadir'});
				printf FH ("area.Type = 'volatile'\n");
				printf FH ("area.ACL = [ '%s', ]\n", $vo);
				printf FH ("\n");
			}

			my($se_access_prots) = $storage_info{$clusref->{'storage'}}{'access_protocols'};
			my($prot);

			foreach $prot (sort keys %{$se_access_prots})
			{
				printf FH ("accessProtocol = storageElement.access_protocols['%s'] = AccessProtocol()\n",
					$prot);
				printf FH ("\n");
				printf FH ("accessProtocol.Type = '%s'\n", $se_access_prots->{$prot}{'type'});
				printf FH ("accessProtocol.Version = '%s'\n",
					$se_access_prots->{$prot}{'gridftp_version'});
				printf FH ("accessProtocol.Endpoint = 'gsiftp://%s:2811'\n",
					$se_access_prots->{$prot}{'gridftp_server'});
				printf FH ("accessProtocol.Capability = [ 'file transfer', 'other capability' ]\n");
				printf FH ("\n");
			}

			# todo: need to verify that it's clusref->{'storage'} should really be used here
#			my($se_control_prots) = $storage_info{$clusref->{'storage'}}{'control_protocols'};
#			my($cprot);
#
#			foreach $cprot (sort keys %{$se_control_prots})
#			{
#				printf FH ("controlProtocol = storageElement.control_protocols['%s'] = ControlProtocol()\n",
#					$cprot);
#				printf FH ("\n");
#				printf FH ("controlProtocol.Type = '%s'\n", $se_control_prots->{$cprot}{'type'});
#				printf FH ("controlProtocol.Version = '%s'\n",
#					$se_control_prots->{$cprot}{'srm_version'});
#				printf FH ("controlProtocol.Endpoint = 'srm://%s:8443'\n",
#					$se_control_prots->{$cprot}{'srm_server'});
#				printf FH ("controlProtocol.Capability = [ 'file transfer', 'other capability' ]\n");
#				printf FH ("\n");
#			}

		} #/if storage defined
	} #/foreach cluster ...
	close(FH);
}

sub make_apac_mipconfig()
{
	open(IFH, ">/tmp/inst-mip.sh") or die("Error create /tmp/inst-mip.sh\n");
	make_source_pl();
	make_cluster_config_pl();
	make_apac_config_py();
	close(IFH);
	printf STDERR ("run sh -x /tmp/inst-mip.sh to activate new mip config.\n");
}

END { }       # module clean-up code here (global destructor)

1;  # don't forget to return a true value from the file

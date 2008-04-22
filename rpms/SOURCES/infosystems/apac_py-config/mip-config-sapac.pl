#!/usr/bin/perl
#
# vim:nohls syntax=none ts=4
#
# make MIP configuration files for APAC National Grid
#
# 2008-13-03, v1.1, Gerson Galang, gerson.galang@sapac.edu.au
#             modified to conform with latest changes to the
#             MIP and apac mip module
#
# 2007-05-08, v1.0, Youzhen Cheng, Youzhen.Cheng@ac3.com.au
#             require file "/usr/local/mip/lib/APAC/mipconfig.pm"
#

use lib "/usr/local/mip/lib";
use APAC::mipconfig;
# use Getopt::Long;

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

#
# Section 1: Site Info (EDIT this section!)
############################################################
chomp($site_domain = `hostname -d`);

%site_info = (
	'name'        => "eRSA",
	'description' => "eResearch SA",
	'location'    => "Adelaide",					# City name only
	'latitude'    => '-34.919517',
	'longitude'   => '138.603226',
	'weburl'      => 'http://www.sapac.edu.au',
	'contact'     => 'grid-admin@sapac.edu.au',
	'domain'      => $site_domain,
# overwrite it as required
#	'domain'      => 'sapac.edu.au',
);


#
# Section 2: Site Storage Info (list of StorageElement)
############################################################
%storage_info  = (
	'hydra-s.' . $site_domain => {
		'root_directory' => '/data/grid',
		'architecture' => 'disk',
		'access_protocols' => {
			'gsiftp1' => {
				type => 'gsiftp',
				gridftp_server => 'ngdata.' . $site_domain,
				gridftp_version => '2.3',
			},

# comment out 'gsiftp2' block if you don't have gridftp on ng2
			'gsiftp2' => {
				type => 'gsiftp',
				gridftp_server => 'ng2.' . $site_domain,
				gridftp_version => '2.3',
			},
		},
	},
# uncomment and modify the following lines if your site supports SRM
# todo: test this block of code
# 	'srm.' . $site_domain => {
# 		'root_directory' => '/data/srm',
# 		'architecture' => 'tape',
#		'control_protocols' => {
#			'srm1' => {
#				type => 'srm'
#				srm_server => 'srm.' . $site_domain,
#				srm_version => '2.1'
#			},
#		},
#	},
);

#
# Section 3: APAC VO Info
############################################################
%vo_info = (

	'/APACGrid/GTest' => {
		'luid' => 'grid.test.vo',			# local Unique ID
		'user' => 'grid-test',				# local account mapped
		'datadir' => '/data/grid/grid-test'	# nfs mounted directory
	},
	'/ARCS/GTest' => {
		'luid' => 'arcs.grid.test.vo',
		'user' => 'grid-test',
		'datadir' => '/data/grid/grid-test'
	},
	'/APACGrid/NGAdmin' => {
		'luid' => 'grid.admin.vo',
		'user' => 'grid-admin',
		'datadir' => '/data/grid/grid-admin'
	},
	'/ARCS/NGAdmin' => {
		'luid' => 'arcs.grid.admin.vo',
		'user' => 'grid-admin',
		'datadir' => '/data/grid/grid-admin'
	},
	'/APACGrid/datatest' => {
		'luid' => 'grid.datatest.vo',
		'user' => 'grid-test',
		'datadir' => '/data/grid/grid-test'
	},
	'/ARCS/datatest' => {
		'luid' => 'arcs.grid.datatest.vo',
		'user' => 'grid-test',
		'datadir' => '/data/grid/grid-test'
	},
	'/APACGrid/SAPAC' => {
		'luid' => 'grid.sapac.vo',
		'user' => 'grid-sapac',
		'datadir' => '/data/grid/grid-sapac'
	},
	'/ARCS/SAPAC' => {
		'luid' => 'arcs.grid.sapac.vo',
		'user' => 'grid-sapac',
		'datadir' => '/data/grid/grid-sapac'
	},
	'/APACGrid/Bio' => {
                'luid' => 'grid.bio.vo',
                'user' => 'grid-bio',
                'datadir' => '/data/grid/grid-bio'
        },
        '/ARCS/Bio' => {
                'luid' => 'arcs.grid.bio.vo',
                'user' => 'grid-bio',
                'datadir' => '/data/grid/grid-bio'
	},
	'/APACGrid/AusBelle' => {
		'luid' => 'grid.ausbelle.vo',
		'user' => 'grid-belle',
		'datadir' => '/data/grid/grid-belle'
	},
	'/ARCS/AusBelle' => {
		'luid' => 'arcs.grid.ausbelle.vo',
		'user' => 'grid-belle',
		'datadir' => '/data/grid/grid-belle'
	},
	'/gin.ggf.org' => {
		'luid' => 'grid.gin.vo',
		'user' => 'grid-gin',
		'datadir' => '/data/grid/grid-gin'
	},
);

#
# Section 4: Cluster Info (Everything about your clusters and queues)
############################################################
%cluster_info = (

# first cluster ( has to be named 'default' )
	'default' => {
		'disabled' => '0',				# publish to MDS
		'name' => 'hydra',				# pbs server name
		'fqdn' => 'hydra.' . $site_domain,		# cluster name (ID)
		'systmp' => '/tmp',				# tmp on gateway
		'usrtmp' => '~/.globus/scratch',		# tmp in user's home
		'storage' => 'hydra-s.' . $site_domain,		# storage supported

		'subclusters' => {

			'sub1' => {

				'PlatformType' => '',
				'SMPSize' => 2,
				'PhysicalCPUs' => 256,
				'LogicalCPUs'  => 256,
				'MainMemory.RAMSize'  => 2055,
				'MainMemory.VirtualSize'  => 6247,

				'optional' => {
				'Processor.Model' => 'Intel(R) Xeon(TM) CPU 2.40GHz',
				'Processor.Vendor' => 'GenuineIntel',
				'Processor.ClockSpeed' => '2392',
				'Processor.InstructionSet' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm',
				'OperatingSystem.Name' => 'Red Hat Enterprise Linux AS release 3 (Taroon Update 4)',
				'OperatingSystem.Release' => 'RedHatEnterpriseAS',
				'OperatingSystem.Version' => '3'
				},
			},

#			'sub2' => {
#				'PhysicalCPUs' => 304,
#				'LogicalCPUs'  => 304,
#				'MainMemory.RAMSize'  => 2048,
#				'MainMemory.VirtualSize'  => 4096,
#			},

		},

		# ANUPBS' queue_system_type is OpenPBS
		'queue_system_type' => 'Torque',
		# job_manager will be 'PBS' if queue_system_type is Torque, PBSPro, OpenPBS
		'job_manager' => 'PBS',
		'default_vos' => [
					'/gin.ggf.org',
					'/ARCS/GTest',
					'/ARCS/NGAdmin',
					'/ARCS/Bio',
					'/ARCS/SAPAC',
					'/ARCS/datatest',
					'/ARCS/AusBelle',
					'/APACGrid/GTest',
					'/APACGrid/NGAdmin',
					'/APACGrid/Bio',
					'/APACGrid/SAPAC',
					'/APACGrid/datatest',
					'/APACGrid/AusBelle',
				],
		'queues'     => {
			'seq' => { },							# vos in default_vos
#			'short' => { },
#			'checkable' => { },
#			'single' => { },
#			'workq' => {
#				'vos' => [ '/APACGrid/OceanModels' ],	# vos listed here
#			},
		},
	},

# second cluster

	'second' => {
		'disabled' => '1',

		'name' => 'swan',
		'fqdn' => 'swan.' . $site_domain,
		'systmp' => '/tmp',
		'usrtmp' => '~/.globus/scratch',
		'storage' => 'ngdata.' . $site_domain,

		'subclusters' => {

			'sub1' => {
				'PlatformType' => '',
				'SMPSize' => 1,
				'PhysicalCPUs' => 16,
				'LogicalCPUs'  => 16,
				'MainMemory.RAMSize'  => 32768,
				'MainMemory.VirtualSize'  => 25853,

				'optional' => {
				'Processor.Model' => 'Itanium 2',
				'Processor.Vendor' => 'GenuineIntel',
				'Processor.ClockSpeed' => '1300',
				'Processor.InstructionSet' => '',
				'OperatingSystem.Name' => 'Red Hat Enterprise Linux',
				'OperatingSystem.Release' => 'AS',
				'OperatingSystem.Version' => '3'
				},
			},

#			'sub2' => {
#				'PhysicalCPUs' => 16,
#				'LogicalCPUs'  => 16,
#				'MainMemory.RAMSize'  => 32768,
#				'MainMemory.VirtualSize'  => 25853,
#			},

		},

		# ANUPBS' queue_system_type is OpenPBS
		'queue_system_type' => 'Torque',
		# job_manager will be 'PBS' if queue_system_type is Torque, PBSPro, OpenPBS
		'job_manager' => 'PBS',
		'default_vos' => [
					'/APACGrid/GTest',
					'/APACGrid/NGAdmin',
					'/APACGrid/OceanModels',
				],
		'queues'     => {
			'express' => { },
			'short' => { },
			'checkable' => { },
			'single' => { },
		},
	},

# third cluster

	'third' => {
		'disabled' => '1',

		'name' => 'gramps',
		'fqdn' => 'gramps.' . $site_domain,
		'systmp' => '/tmp',
		'usrtmp' => '~/.globus/scratch',
#		'storage' => '',

		'subclusters' => {

			'sub1' => {
				'PlatformType' => '',
				'SMPSize' => 1,
				'PhysicalCPUs' => 2,
				'LogicalCPUs'  => 2,
				'MainMemory.RAMSize'  => 512,
				'MainMemory.VirtualSize'  => 512,

				'optional' => {
				'Processor.Model' => 'Intel(R) Pentium(R) III CPU',
				'Processor.Vendor' => 'GenuineIntel',
				'Processor.ClockSpeed' => '1263',
				'Processor.InstructionSet' => 'fpu vme de pse tsc msr pae mce cx8 apic mtrr pge mca cmov pat pse36 mmx fxsr sse',
				'OperatingSystem.Name' => 'RedHat Linux',
				'OperatingSystem.Release' => 'Fedora Core',
				'OperatingSystem.Version' => '2'
				},
			},

#			'sub2' => {
#				'PhysicalCPUs' => 2,
#				'LogicalCPUs'  => 2,
#				'MainMemory.RAMSize'  => 512,
#				'MainMemory.VirtualSize'  => 512,
#			},

		},

		# ANUPBS' queue_system_type is OpenPBS
		'queue_system_type' => 'Torque',
		# job_manager will be 'PBS' if queue_system_type is Torque, PBSPro, OpenPBS
		'job_manager' => 'PBS',
		'default_vos' => [
					'/APACGrid/GTest',
					'/APACGrid/NGAdmin',
				],
		'queues'     => {
			'express' => { },
			'workq' => { },
		},
	},
);

#
# Section 5: Gateway Info (edit it for non-std install)
############################################################
chomp($gateway_hostname = `hostname -f`);

%gateway_info = (
	'fqdn' => $gateway_hostname,
	#'fqdn'    => 'ng2.' . $site_domain;
	'qstat'     => '/usr/local/bin/qstat',
	'pbsnodes'  => '/usr/local/bin/pbsnodes',
	'globus_version'  => '4.0.5'
);

#
# main
#
make_apac_mipconfig();

exit(0);
#-eof-

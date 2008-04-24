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
	'name'        => "VPAC",
	'description' => "Victorian Partnership for Advanced Computing",
	'location'    => "Melbourne",					# City name only
	'latitude'    => '-37.80650',
	'longitude'   => '144.96360',
	'weburl'      => 'http://www.vpac.org',
	'contact'     => 'help@vpac.org',
	'domain'      => $site_domain,
# overwrite it as required
#	'domain'      => 'sapac.edu.au',
);


#
# Section 2: Site Storage Info (list of StorageElement)
############################################################
%storage_info  = (
	'hydra-s.' . $site_domain => {
		'root_directory' => '/home',
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
		'datadir' => '/home/grid-test'	# nfs mounted directory
	},
# no GTest vo for /ARCS exists yet
#	'/ARCS/GTest' => {
#		'luid' => 'arcs.grid.test.vo',
#		'user' => 'grid-test',
#		'datadir' => '/home/grid-test'
#	},
        '/APACGrid/NGAdmin' => {
		'luid' => 'grid.admin.vo',
		'user' => 'grid-admin',
		'datadir' => '/home/grid-admin'
	},
	'/ARCS/NGAdmin' => {
		'luid' => 'arcs.grid.admin.vo',
		'user' => 'grid-admin',
		'datadir' => '/home/grid-admin'
	},
## demo VU is currently not supported
#	'/APACGrid/Demo' => {
#		'luid' => 'grid.demo.vo',
#		'user' => 'grid-vpac',
#		'datadir' => '/home/grid-vpac'
#	},
	'/APACGrid/AusBelle' => {
		'luid' => 'grid.ausbelle.vo',
		'user' => 'grid-belle',
		'datadir' => '/home/grid-belle'
	},
        '/APACGrid/Lifesci' => {
                'luid' => 'grid.lifesci.vo',
                'user' => 'grid-lifesci',
                'datadir' => '/home/grid-lifesci'
        },
## monash is only supported on monash hosts
#        '/APACGrid/Monash' => {
#                'luid' => 'grid.monash.vo',
#                'user' => 'grid-monash',
#                'datadir' => '/home/grid-monash'
#        },
#        '/ARCS/Monash' => {
#                'luid' => 'arcs.grid.monash.vo',
#                'user' => 'grid-monash',
#                'datadir' => '/home/grid-monash'
#        },
        '/APACGrid/MonashGeo' => {
                'luid' => 'grid.monashgeo.vo',
                'user' => 'grid-mongeo',
                'datadir' => '/home/grid-mongeo'
        },
        '/ARCS/MonashGeo' => {
                'luid' => 'arcs.grid.monashgeo.vo',
                'user' => 'grid-belle',
                'datadir' => '/home/grid-belle'
        },
        '/APACGrid/Nimrod' => {
                'luid' => 'grid.nimrod.vo',
                'user' => 'grid-nimrod',
                'datadir' => '/home/grid-nimrod'
        },
        '/ARCS/Nimrod' => {
                'luid' => 'arcs.grid.nimrod.vo',
                'user' => 'grid-nimrod',
                'datadir' => '/home/grid-nimrod'
        },
        '/APACGrid/OceanModels' => {
                'luid' => 'grid.oceanmodels.vo',
                'user' => 'grid-ocean',
                'datadir' => '/home/grid-ocean'
        },
        '/ARCS/OceanModels' => {
                'luid' => 'arcs.grid.oceanmodels.vo',
                'user' => 'grid-belle',
                'datadir' => '/home/grid-belle'
        },
        '/ARCS/StartUp' => {
                'luid' => 'arcs.grid.startup.vo',
                'user' => 'grid-startup',
                'datadir' => '/home/grid-startup'
        },
        '/APACGrid/TestChem' => {
                'luid' => 'grid.testchem.vo',
                'user' => 'grid-tchem',
                'datadir' => '/home/grid-tchem'
        },
## vpac is only supported on monash hosts
#        '/APACGrid/VPAC' => {
#                'luid' => 'grid.vpac.vo',
#                'user' => 'grid-vpac',
#                'datadir' => '/home/grid-vpac'
#        },
#        '/ARCS/VPAC' => {
#                'luid' => 'arcs.grid.vpac.vo',
#                'user' => 'grid-vpac',
#                'datadir' => '/home/grid-vpac'
#        },
        '/APACGrid/Workshop' => {
                'luid' => 'grid.workshop.vo',
                'user' => 'grid-vpac',
                'datadir' => '/home/grid-vpac'
        },
	'/gin.ggf.org' => {
		'luid' => 'grid.gin.vo',
		'user' => 'grid-gin',
		'datadir' => '/home/grid-gin'
	},
);

#
# Section 4: Cluster Info (Everything about your clusters and queues)
############################################################
%cluster_info = (

# first cluster ( has to be named 'default' )
	'default' => {
		'disabled' => '0',				# publish to MDS
		'name' => 'tango-m',				# pbs server name
		'fqdn' => 'tango.' . $site_domain,		# cluster name (ID)
		'systmp' => '/tmp',				# tmp on gateway
		'usrtmp' => '~/.globus/scratch',		# tmp in user's home
		'storage' => 'ngdata.' . $site_domain,		# storage supported

		'subclusters' => {

			'sub1' => {

				'PlatformType' => 'AMD64',
				'SMPSize' => 1,
				'PhysicalCPUs' => 170,
				'LogicalCPUs'  => 446,
				'MainMemory.RAMSize'  => 32768,
				'MainMemory.VirtualSize'  => 32768,

				'optional' => {
				'Processor.Model' => 'Dual-Core AMD Opteron(tm) Processor 2212',
				'Processor.Vendor' => 'AuthenticAMD',
				'Processor.ClockSpeed' => '2010',
				'Processor.InstructionSet' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt rdtscp lm 3dnowext 3dnow rep_good pni cx16 lahf_lm cmp_legacy svm extapic cr8_legacy',
				'OperatingSystem.Name' => 'CentOS',
				'OperatingSystem.Release' => '5',
				'OperatingSystem.Version' => '5'
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
                                        '/APACGrid/GTest',
                                        '/APACGrid/NGAdmin',
                                        '/ARCS/NGAdmin',
                                        '/APACGrid/AusBelle',
                                        '/APACGrid/Lifesci',
                                        '/APACGrid/MonashGeo',
                                        '/ARCS/MonashGeo',
                                        '/APACGrid/Nimrod',
                                        '/ARCS/Nimrod',
                                        '/APACGrid/OceanModels',
                                        '/ARCS/OceanModels',
                                        '/ARCS/StartUp',
                                        '/APACGrid/TestChem',
                                        '/APACGrid/Workshop',
                                        '/gin.ggf.org',
				],
		'queues'     => {
			'sque' => { },							# vos in default_vos
			'dque' => { },
#			'checkable' => { },
#			'single' => { },
#			'workq' => {
#				'vos' => [ '/APACGrid/OceanModels' ],	# vos listed here
#			},
		},
	},

# second cluster

	'second' => {
		'disabled' => '0',

		'name' => 'edda-m',
		'fqdn' => 'edda.' . $site_domain,
		'systmp' => '/tmp',
		'usrtmp' => '~/.globus/scratch',
		'storage' => 'ngdata.' . $site_domain,

		'subclusters' => {

			'sub1' => {
				'PlatformType' => 'Power5',
				'SMPSize' => 1,
				'PhysicalCPUs' => 46,
				'LogicalCPUs'  => 184,
				'MainMemory.RAMSize'  => 8192,
				'MainMemory.VirtualSize'  => 8192,

				'optional' => {
				'Processor.Model' => '',
				'Processor.Vendor' => 'IBM',
				'Processor.ClockSpeed' => '1654',
				'Processor.InstructionSet' => '',
				'OperatingSystem.Name' => 'Suse Linux',
				'OperatingSystem.Release' => '',
				'OperatingSystem.Version' => ''
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
                                        '/ARCS/NGAdmin',
                                        '/APACGrid/AusBelle',
                                        '/APACGrid/Lifesci',
                                        '/APACGrid/MonashGeo',
                                        '/ARCS/MonashGeo',
                                        '/APACGrid/Nimrod',
                                        '/ARCS/Nimrod',
                                        '/APACGrid/OceanModels',
                                        '/ARCS/OceanModels',
                                        '/ARCS/StartUp',
                                        '/APACGrid/TestChem',
                                        '/APACGrid/Workshop',
                                        '/gin.ggf.org',
				],
		'queues'     => {
			'dque' => { },
			'sque' => { },
#			'checkable' => { },
#			'single' => { },
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

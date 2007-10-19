vdt_location    => "/usr/local/osg",

# The following variables are in relation to vdt_location
gatekeeper_conf => "/globus/etc/globus-gatekeeper.conf",
vdt_version     => "/vdt/bin/vdt-version",
ml_prop         => "/vdt-app-data/MonaLisa/monalisa.properties",
osg_attrib      => "/monitoring/osg-attributes.conf",
vo_map          => "/monitoring/grid3-user-vo-map.txt",
mkgridmap		 => "/edg/etc/edg-mkgridmap.conf",

# Condor specific configuration
condor_path     => "/usr/local/bin",
condor_config   => "/usr/local/condor/etc/condor_config",

# PBS specific configuration
#pbs_host        => "osg-lcg.its.uiowa.edu",
pbs_path        => "/usr/local/torque/bin",

# The following variables are in relation to OSG_APP_DIR defined in osg_attrib above
grid3_locations => "/etc/grid3-locations.txt",

# allow_{in,out}bound does a check, but this allows you to override the values
#allow_outbound => 'FALSE',
#allow_inbound => 'FALSE',

sc_nodes        => 20,

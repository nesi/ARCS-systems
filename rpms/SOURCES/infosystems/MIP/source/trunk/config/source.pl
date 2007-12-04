# These directories are created by install_mip
mipdir     => '/home/eshook/Projects/MIP/mip',
moduledir  => '/home/eshook/Projects/MIP/mip/modules',
configdir  => '/home/eshook/Projects/MIP/mip/config',

# Packages are ordered in terms of priority
#     left - lowest priority
#     right - highest priority
pkgs       => ['osg','int','site',],

# Default producer to use
producer   => 'glue',

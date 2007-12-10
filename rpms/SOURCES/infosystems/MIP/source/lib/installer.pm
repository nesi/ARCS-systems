#!/usr/bin/perl -w
use strict;

use File::Copy;
use File::Path;
use File::Basename;
use Sys::Hostname;
use Cwd;

#FIXME: MIP_CONFIG_DIR should be pulled from the config dir
#			This should be done in the executable, not library

my $MIP_CONFIG_DIR="/home/hansent/Desktop/mip/config";

####################################
## Installer methods ###############
####################################
sub install_mip{
	my($mipdir, $vdt_location,$defaultproducer, @pkgs) = @_;
   die "Please cd to MIP directory then run ./install_mip" if not -e "$mipdir/mip.pl";
#   die "Please set VDT_LOCATION before installing MIP" if not -d "$vdt_location";
   createsource($mipdir,"$mipdir/config","$mipdir/modules",$defaultproducer,@pkgs);
   createmip($mipdir,"$mipdir/config",$vdt_location);
#   createlink("$mipdir/modules");
}
sub createsource
{  # creates the source.pl file
	my ($mipdir,$configdir,$moduledir,$defaultproducer,@pkgs)=@_;
	open(outfile, ">$configdir/source.pl") or die "cannot write to source.pl";
	print outfile "# These directories are created by install_mip\n" .
				"mipdir     => '$mipdir',\n" .
				"moduledir  => '$moduledir',\n" .
				"configdir  => '$configdir',\n\n" .
				"# Packages are ordered in terms of priority\n" .
				"#     left - lowest priority\n" .
				"#     right - highest priority\n" .
				"pkgs       => [";
	foreach my $pkg (@pkgs) {
		print outfile "'$pkg',";
	}
	print outfile "],\n\n";
	print outfile "# Default producer to use\n" .
					"producer   => \'$defaultproducer\',\n";
	close(outfile);
}

sub createmip
{  # Creates the 'mip' file
	my ($mipdir,$configdir,$vdt_location)=@_;
	open(outfile, ">$mipdir/mip") or die "cannot write 'mip'";
	print outfile "#!/bin/bash\n" .
		"LANG=C\n" .
#		". $vdt_location/setup.sh\n" .
		"export PYTHONPATH=\"$mipdir/modules/apac_py:\$PYTHONPATH\"\n" .
		"cd $mipdir\n" .
		"if [ ! -z \"\$1\" ]; then\n" .
		"   if [ \"\$1\" == \"-remote\" ]; then\n" .
		"      ./mip-remote.pl $configdir\n" .
		"   elif [ \"\$1\" == \"-int\" -o \"\$1\" == \"-integrator\" ]; then\n" .
		"      ./integrator.pl $configdir\n" .
		"   else\n" .
		"      ./mip.pl \$1\n" .
		"   fi\n" .
		"else\n" .
		"   ./mip.pl\n" .
		"fi\n";
	close(outfile);
	chmod 0755, "$mipdir/mip";
}

#sub createlink
#{
#	my ($moduledir)=@_;
#	if (-e "$moduledir/apac_py") {
#		symlink("$moduledir/apac_py", "$moduledir/default") || die "ERROR: Cannot symlink to $moduledir/apac_py!\n";
#	}
#	else {
#		print "ERROR:  Cannot symlink default to apac_py. Try to install the apac_py module first before running
#	the install_mip script\n";
#	}
#}

## install_pkg
##    Installs a MIP package to an existing MIP installation
##    The mip package is extarcted and configured on the fly
##    by running the modules configuration file (which may choose
##    to alter the package's moduel list).  Then the module list
##    is read and each module listed is installed to the MIP
##    installation.
sub install_pkg{
   my ($pkg_name) = @_;

	my ($pkg_file,%mip_config,%pkg_config,$input,@clusterlist);
	my (%uids,$hostname,$current_dir,$tmpdir,%roots,@mod_list);

   $pkg_file="$pkg_name.tar.gz";
   %mip_config=get_conf("source.pl");
   %pkg_config=get_conf("$pkg_name.pl");

   #prompt for cluster list and create pkg_name.pl configuration file
   print "Please enter all cluster names that should be in this package's cluster list (space seperated):";
   $input=<STDIN>;
   chomp($input);
   @clusterlist=split(' ',$input);
   add_conf_val(\%pkg_config,"clusterlist",\@clusterlist);

   #create a uid (hostname for now)
   %uids=();
   $hostname=`hostname`;
   $uids{Site}=[$hostname,];

   save_conf(\%pkg_config);

   #extract gzipped tarball to tmp dir
   $current_dir = cwd();
   $tmpdir = "$mip_config{mipdir}/tmp";
#FIXME: Remove below?
print "TEMP: $tmpdir";

   mkdir("$tmpdir");
   copy($pkg_file, $tmpdir);
   chdir("$tmpdir");
   die "Error: Failed to untar package" if system("tar -xzf $pkg_file") !=0;
   chdir($current_dir); #change back to old directory

   #configure pkg by running package config file
#FIXME: Die if not -e?
   if (-e "config"){
      do "$tmpdir/config";
   }

   #create package module directory if it doesnt exist yet
   mkdir("$mip_config{mipdir}/modules/$pkg_name");# unless (-d "$mip_config{mipdir}/$pkg_name");

   #read module list to get modules to be installed
   open(FILE, "$tmpdir/modules") or die("Unable to open module list file.");
   @mod_list=<FILE>;
   close(FILE);

   #install each module from module list and check what roots should be installed
   %roots = ();
   foreach my $mod (@mod_list){
     chomp $mod;
     unless($mod eq ""){
         $mod =~ /(.*)\//;
         my $root = $1;

         #if the root hasn't come up yet ask whether we want to install it
         unless ($roots{$root}){
            print "Would you like to install the $root Root?\n";
            my $inputline = <STDIN>;
            chomp($inputline);
            if($inputline =~ /^y.*/){
               $roots{$root} = 1;
            }
            else{
               $roots{$root} = -1;
            }
         }

        #install if its part of a root we want installed
        if($roots{$root} == 1){
           $uids{"$root"} = ["$root-uid",];
           install_mod($pkg_name, $root, "$tmpdir/$pkg_name/$mod");
        }
     }
   }

   #put uid hash in config file
   add_conf_val(\%pkg_config, "uids", \%uids);
   save_conf(\%pkg_config);

   #all done...remove tmp diretory
   rmtree($tmpdir ,0,1)
}


## install_mod
##    installs a single mod file to the MIP
##    basically copies the sepcified file to teh right directory (mipdir/pkg/root/module.pl)
##    also, if it exists runs the optional module configuration file (living in teh same dir
##    as teh module and named the same plus a ".conf" suffix)

sub install_mod{
   my ($pkg_name, $root, $mod_file) = @_;

	my (%config,$mod_name,$dest);
   my %config = get_conf("source.pl");

   #configure module specific stuff in option module conf file
   if (-e "$mod_file.conf"){
      do "$mod_file.conf";
   }

   #create root dir if it doesnt exist yet
   mkdir("$config{moduledir}/$pkg_name/$root") unless (-d "$config{mipdir}/modules/$pkg_name/$root" );

   #copy file to module/root dir of desired pkg;
   $mod_name = basename("$mod_file");
   $dest = "$config{moduledir}/$pkg_name/$root/$mod_name";
   copy($mod_file, $dest) or die "Error:  Could not install $mod_name for package $pkg_name (Failed to copy '$mod_file' to '$dest')";
}




#####################################
## Configuration methods ############
#####################################


## get_conf
##    grabs teh specified configuration file from the MIP config directory
##    returns a handle to the configuration hash
sub get_conf{
   my ($conf_file)=@_;

   #read conf file
   my %config=();
   %config=do "$MIP_CONFIG_DIR/$conf_file" if -e "$MIP_CONFIG_DIR/$conf_file";

   #add some state vars to conf hash
   $config{__updated__}=0;
   $config{__filename__}=$conf_file;

   return %config;
}


## save_conf
##    writes the configuration hash to the original file
##    it only writes if the configuration has been updated
sub save_conf{
   my ($conf)=@_;

	my ($file_contents,$fname);
   return unless ($conf->{__updated__}==1);

   $file_contents=__hsh_to_str($conf);

   $fname="$MIP_CONFIG_DIR/$conf->{__filename__}";
   `touch $fname` unless (-e $fname);
   open(OUTP, "> $fname") or die("Cannot open file '$fname' for writing\n");
   print OUTP $file_contents;
   close OUTP;
}

#FIXME: Integrator has code to write this already
#			We should find a combination of these two methods and abstract out into single library
#			Possibly put it in {utility,}functions


## __hsh_to_str
##    this function converts a configuration hash to a string that can be written to file
##    the output can be sourced into a hash by any perl  script
##    it handles sub-hashes and padds the lines for readability
sub __hsh_to_str{
   my ($hsh, $padding)=@_;
   my $str='';

   foreach my $key(keys %{$hsh}){
      my $val=$hsh->{$key};
      $str .= "   " if $padding;

      #recurse if its an hash
      if(ref($val) eq "HASH"){
         $str .= "$key => { \n". __hsh_to_str($val, 1)."},";
      }
      #write out the array
      elsif(ref($val) eq "ARRAY"){
         $str .= "$key => [";
         foreach(@{$val}){
            $str .= " \"$_\", ";
         }
         $str .= "], \n";
      }
      #its a number or a string
      else{
         $str .= "$key => \"$val\",\n " unless ($key eq "__filename__" || $key eq "__updated__");
      }
   }
   return $str;
}


## add-config_val
##    simply adds a key/value pair to the configuration
##    also flags the congiguration hash as updated
sub add_conf_val{
   my ($conf, $key, $val) = @_;

   #add key/value and mark conf as updated
   $conf->{$key} = $val;
   $conf->{__updated__} = 1;
   return
}


## prompt_config_val
##    prints the specified prompt and lets user input a desired value
##    if the user hits <enter>, the specified default value will be set
sub prompt_conf_val{
   my ($conf, $prompt, $key, $default_val) = @_;

   #interactive prompt for conf value
   print $prompt."[$default_val]:\n";

   my $inputline = <STDIN>;
   chomp($inputline);
   $default_val = $inputline unless ($inputline eq '');

   $conf->{$key} = $default_val;
   $conf->{__updated__} = 1;
}



## rem_conf_val
##    removes a key/value pair from teh configuration hash
##    also flag the configuration hash as updated
sub rem_conf_val{
   my ($conf, $key) = @_;

   #remove conf value from hash
   delete $conf->{$key};
   $conf->{__updated__} = 1;
}




#FIXME: Remove the tests below before shipping


# Some simple tests  (uncomment and run this file directly test)

#my %conf =  get_conf("osg2.pl");
#print __hsh_to_str(\%conf);
#save_conf(\%conf);
#print $conf{__filename__}."\n";
#add_conf_val(\%conf, "newval", "foo");
#print $conf{"newval"}."\n";
#prompt_conf_val(\%conf, "enter the path", "path", "/my/path");
#rem_conf_val(\%conf, "path");
#print $conf{path}."\n";
#print $conf{__updated__}."\n";


# install_pkg("/home/hansent/mip-0.2/mypkg.tar.gz", "mypkg");


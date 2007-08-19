%define PREFIX /usr/local

Summary: Mip configuration help for APAC gateways
Name: APAC-gateway-config-mip
Version: 0.1
Release: 1
Copyright: Apache
Group: Applications/Internet
Requires: APAC-mip
Buildroot: /tmp/%{name}-builtroot
BuildArch: noarch

%description
Mip configuration help for APAC gateways

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{PREFIX}/sbin

cat <<EOF > $RPM_BUILD_ROOT%{PREFIX}/sbin/configure_mip
#!/bin/sh

cat <<-END > %{PREFIX}/mip/config/source.pl

	# base directories
	mipdir => '%{PREFIX}/mip',
	moduledir => '%{PREFIX}/mip/modules',
	configdir => '%{PREFIX}/mip/config',

	# Packages are ordered in terms of priority
	#     left - lowest priority
	#     right - highest priority
	pkgs => [ 'apac', 'int', ],

	# Default producer to use
	producer => 'glue',

END

cat <<END > %{PREFIX}/mip/mip
#!/bin/sh

LANG=C

cd %{PREFIX}/mip
case "\\\$1" in
	-remote) ./mip-remote.pl %{PREFIX}/mip/config \\\$2;;
	-int|-integrator) ./integrator.pl %{PREFIX}/mip/config ;;
	*) ./mip.pl \\\$1;;
esac



EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%{PREFIX}/sbin/configure_mip

%changelog


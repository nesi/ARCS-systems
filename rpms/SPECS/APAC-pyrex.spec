#
# spec file for package pyrex (Version 0.9.4.1)
#
# Copyright (c) 2007 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
# usedforbuild    aaa_base acl attr audit-libs autoconf automake bash bind-libs bind-utils binutils bison bzip2 coreutils cpio cpp cpp41 cracklib cvs cyrus-sasl db diffutils e2fsprogs file filesystem fillup findutils flex gawk gcc gcc41 gdbm gdbm-devel gettext gettext-devel glibc glibc-devel glibc-locale gpm grep groff gzip info insserv klogd less libacl libattr libcom_err libgcc41 libltdl libmudflap41 libnscd libstdc++41 libtool libvolume_id libxcrypt libzio linux-kernel-headers m4 make man mktemp module-init-tools ncurses ncurses-devel net-tools netcfg openldap2-client openssl pam pam-modules patch perl permissions pkg-config popt procinfo procps psmisc pwdutils python python-devel rcs readline rpm sed sqlite strace sysvinit tar tcpd texinfo timezone unzip util-linux vim zlib zlib-devel

Name: APAC-pyrex
BuildRequires: pkgconfig python-devel
Requires: python
URL: http://nz.cosc.canterbury.ac.nz/~greg/python/Pyrex/
License: Other uncritical OpenSource License
Group: Development/Languages/Python
Version: 0.9.4.1
Release: 1
Autoreqprov: on
Summary: Pyrex lets you write code that mixes Python and C data types any way you want, and compiles it into a C extension for Python.
Source0: Pyrex-%{version}.tar.gz
Patch0: pyrex-initialize-lineno-thoenig-01.patch
Patch1: pyrex-python-2.5.patch
BuildRoot: %{_tmppath}/%{name}-%{version}-build

%description
Pyrex is a language specially designed for writing Python extension
modules. It's designed to bridge the gap between the nice, high-level,
easy-to-use world of Python and the messy, low-level world of C.

http://www.cosc.canterbury.ac.nz/~greg/python/Pyrex/



Authors:
--------
    Greg Ewing (greg@cosc.canterbury.ac.nz )

%prep
%setup -n Pyrex-%{version} -q
%patch0 -p0
%patch1 -p0

%build
export CFLAGS="$RPM_OPT_FLAGS" 
python setup.py build

%install
python setup.py install --prefix=%{_prefix} --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-, root, root)
%doc *.txt Doc/*
%doc Demos 


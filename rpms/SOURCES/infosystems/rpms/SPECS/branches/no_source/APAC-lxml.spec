#
# spec file for package python-lxml (Version 1.1.2)
#
# Copyright (c) 2007 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# usedforbuild    aaa_base acl attr audit-libs autoconf automake bash bind-libs bind-utils binutils bison bzip2 coreutils cpio cpp cpp41 cracklib cvs cyrus-sasl db diffutils e2fsprogs file filesystem fillup findutils flex gawk gcc gcc41 gdbm gdbm-devel gettext gettext-devel glibc glibc-devel glibc-locale gpm grep groff gzip info insserv klogd less libacl libattr libcom_err libgcc41 libgcrypt libgcrypt-devel libgpg-error libgpg-error-devel libltdl libmudflap41 libnscd libstdc++41 libtool libvolume_id libxcrypt libxml2 libxml2-devel libxslt libxslt-devel libzio linux-kernel-headers m4 make man mktemp module-init-tools ncurses ncurses-devel net-tools netcfg openldap2-client openssl pam pam-modules patch perl permissions popt procinfo procps psmisc pwdutils pyrex python python-devel python-xml pyxml rcs readline rpm sed sqlite strace sysvinit tar tcpd texinfo timezone unzip util-linux vim zlib zlib-devel

Name:           APAC-lxml
%define modname lxml
URL:            http://codespeak.net/lxml
Summary:        A Pythonic binding for the libxml2 and libxslt libraries
Version:        svn_rev37576
Release:        1
License:        BSD License and BSD-like
Group:          Development/Libraries/Python
Source:         %{modname}-%{version}.tar.bz2
Requires:       libxml2 libxslt
BuildRequires:  libxml2-devel libxslt-devel APAC-pyrex python-devel

%description
lxml is a Pythonic binding for the libxml2 and libxslt libraries. It
follows the ElementTree API as much as possible, building it on top of
the native libxml2 tree. It also extends this API to expose libxml2 and
libxslt specific functionality, such as XPath, Relax NG, XML Schema,
XSLT, and c14n.



Authors:
--------
    Stefan Behnel - main developer and maintainer
    Martijn Faassen - creator of lxml and initial main developer
    and others

%prep
%setup -q -n %{modname}-%{version}

%build
export CFLAGS="$RPM_OPT_FLAGS"
python setup.py build

%install
rm -rf %{buildroot}
python setup.py install --prefix=%{_prefix} --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-,root,root)
%doc doc CHANGES.txt CREDITS.txt LICENSES.txt README.txt TODO.txt



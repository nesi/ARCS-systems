%define major_version 2.0
%define minor_version 1.1.1
%define package_name mod_auth_pam

Name: APAC-%{package_name}
Version: %{major_version}.%{minor_version}
Release: 1
Summary: This is a PAM authentication module for Apache
Group: Web
License: GPL
Source: http://pam.sourceforge.net/mod_auth_pam/dist/mod_auth_pam-%{major_version}-%{minor_version}.tar.gz
URL: http://pam.sourceforge.net/mod_auth_pam/
PreReq: httpd, perl
Buildrequires: httpd-devel >= 2.0, pam-devel
BuildRoot: %{_tmppath}/%{name}-%{version}-root

%description
This is an authentication module for Apache that allows you to authenticate
HTTP clients using user entries in an PAM directory.

%prep
%setup -q -n %{package_name}
 
%build
make APXS=%{_sbindir}/apxs

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_libdir}/httpd/modules
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
install -m 755 .libs/mod_auth_pam.so %{buildroot}%{_libdir}/httpd/modules
install -m 755 .libs/mod_auth_sys_group.so %{buildroot}%{_libdir}/httpd/modules

cat > %{buildroot}%{_sysconfdir}/httpd/conf.d/mod_auth_pam.conf <<EOF
#
# mod_auth_pam.conf
#

LoadModule auth_pam_module       modules/mod_auth_pam.so
LoadModule auth_sys_group_module modules/mod_auth_sys_group.so

EOF

mkdir -p %{buildroot}%{_sysconfdir}/pam.d
cat > %{buildroot}%{_sysconfdir}/pam.d/httpd <<EOF
#%PAM-1.0
# NOTE: This is just a sample file. Apache won't be able to
# authenticate your users with pam_unix.so because it can't
# read /etc/shadow. Check the URL below for some hints or
# use another pam module which doesn't require root privileges
# (such as LDAP, for example):
#
# http://pam.sourceforge.net/mod_auth_pam/shadow.html
#
auth       required     pam_stack.so service=system-auth
account    required     pam_stack.so service=system-auth

EOF

# remove useless dirs
find . -name CVS -exec rm -rf {} \; > /dev/null 2>&1 || :

%clean
rm -rf %{buildroot}

%files
%defattr(0644,root,root,0755)
%doc doc samples INSTALL README
%{_libdir}/httpd/modules/*.so
%config(noreplace) %{_sysconfdir}/httpd/conf.d/mod_auth_pam.conf
%config(noreplace) %{_sysconfdir}/pam.d/httpd



%changelog
* Tue Nov 14 2006 Andrew Sharpe
- modified for httpd

* Tue Mar 18 2003 Andreas Hasenack <andreas@conectiva.com.br>
+ 2003-03-18 16:54:49 (28387)
- updated to version 2.0-1.1.1 which supports Apache 2
- Closes: #7428
- created conf.d/mod_auth_pam.module
- created new /etc/pam.d/httpd file with comments about the problem
  with apache and its inability (good!) to read /etc/shadow. Should
  help newbies (or not).
- removed %%post section, no need to alter the main httpd.conf file with
  our new conf.d/*.module structure
- I *could* make it restart apache in %%post, but I'm not sure. Some of
  our packages do it, others don't. Anyway, the module will be loaded
  the next time apache is started.

* Thu Aug 29 2002 Gustavo Niemeyer <niemeyer@conectiva.com>
+ 2002-08-29 18:24:43 (8780)
- Copying release 1.0a-5cl to releases/ directory.

* Thu Aug 29 2002 Gustavo Niemeyer <niemeyer@conectiva.com>
+ 2002-08-29 18:24:42 (8779)
- Copying release 1.0a-5cl to pristine/ directory.

* Thu Aug 29 2002 Gustavo Niemeyer <niemeyer@conectiva.com>
+ 2002-08-29 18:24:40 (8778)
- Imported package from 8.0.

* Thu Aug 29 2002 Gustavo Niemeyer <niemeyer@conectiva.com>
+ 2002-08-29 18:24:36 (8777)
- Created package directory

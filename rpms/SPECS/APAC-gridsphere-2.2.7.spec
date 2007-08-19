%define package_name gridsphere
%define PREFIX /usr/local

Summary: The GridSphere portal framework provides an open-source portlet based Web portal. 
Name: APAC-%{package_name}
Version: 2.2.7
Release: 1
Copyright: GRIDSPHERE SOFTWARE LICENSE
Group: Applications/Internet
Source: %{package_name}-2.2.7-src.tgz
Patch: %{package_name}-2.2.7.patch
Requires: APAC-gateway-config-tomcat
Buildrequires: APAC-gateway-config-tomcat, APAC-gateway-config-ant, APAC-gateway-config-java
BuildArch: noarch
#BuildRoot: /tmp/%{package_name}-buildroot

%description
The GridSphere portal framework provides an open-source portlet based Web portal. GridSphere enables developers to quickly develop and package third-party portlet web applications that can be run and administered within the GridSphere portlet container.

NOTE: The author thinks this package is _not_ suited to RPM.  There are too many bits in this package that live in the same filesystem space but belong to different RPMs, which makes directory ownership a problem (RPM ownership).  Updating might also prove difficult.


%prep
%setup -q -n %{package_name}-%{version}
%patch -p1


%build
# pull in JAVA_HOME ANT_HOME CATALINA_HOME
source /etc/profile
export TOMCAT_HOME=$CATALINA_HOME
ant jar

%install
rm -rf $RPM_BUILD_ROOT
source /etc/profile

mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
cp -a * $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
find . -type f | sed -e "s|^\.|%{PREFIX}/%{package_name}|" > devel_files.list
find . -type d | sed -e "s|^\.|%dir %{PREFIX}/%{package_name}|" >> devel_files.list

export TOMCAT_HOME=$CATALINA_HOME
# deals with symlink
export CATALINA_HOME=`echo ${RPM_BUILD_ROOT}${CATALINA_HOME} | sed -e "s|/$||"`
mkdir -p $CATALINA_HOME

for i in $TOMCAT_HOME/*; do
	[ -d $i ] && mkdir -p ${CATALINA_HOME}/${i/*\/}
done
mkdir -p $CATALINA_HOME/shared/lib
mkdir -p $CATALINA_HOME/common/lib
mkdir -p $CATALINA_HOME/common/classes
mkdir -p $CATALINA_HOME/conf/Catalina/localhost

# directories not owned by this RPM
find $CATALINA_HOME -type d | sed -e "s|^${RPM_BUILD_ROOT}||" > pre_directories.list

ant install

# create file lists
find $CATALINA_HOME -path $CATALINA_HOME/webapps/%{package_name}/docs -prune -o -type d -print | sed -e "s|^${RPM_BUILD_ROOT}||" > post_directories.list
find $CATALINA_HOME -path $CATALINA_HOME/webapps/%{package_name}/docs -prune -o -type f -print | sed -e "s|^${RPM_BUILD_ROOT}||" > files.list

comm -2 -3 post_directories.list pre_directories.list | sed -e "s/^/%dir /" >> files.list

find $CATALINA_HOME -path $CATALINA_HOME/webapps/%{package_name}/docs/\* -type d -print | sed -e "s|^${RPM_BUILD_ROOT}|%dir |" > doc_files.list
find $CATALINA_HOME -path $CATALINA_HOME/webapps/%{package_name}/docs/\* -type f -print | sed -e "s|^${RPM_BUILD_ROOT}||" >> doc_files.list


# tone down logging
perl -pi -e "s|^(log4j.rootCategory.*), LOGFILE|\1|g" $CATALINA_HOME/webapps/%{package_name}/WEB-INF/classes/log4j.properties
perl -pi -e "s|DEBUG|ERROR|g" $CATALINA_HOME/webapps/%{package_name}/WEB-INF/classes/log4j.properties


# fix database url
perl -pi -e "s|${RPM_BUILD_ROOT}||" $CATALINA_HOME/webapps/%{package_name}/WEB-INF/CustomPortal/database/hibernate.properties


# remove references to TOMCAT_HOME
find $RPM_BUILD_ROOT%{PREFIX}/${package_name} -name \*.xml -exec perl -pi -e "s/env\.TOMCAT_HOME/env.CATALINA_HOME/g" {} \;

%clean
rm -rf $RPM_BUILD_ROOT

%files -f files.list
%defattr(-,tomcat,tomcat)

%post
source /etc/profile
perl -pi -e "s|(</tomcat-users>)|  <user username=\"gridsphere\" password=\"gridsphere\" roles=\"manager\"/>\n\1|" $CATALINA_HOME/conf/tomcat-users.xml
chown -R tomcat:tomcat $CATALINA_HOME/webapps/%{package_name}

%package devel
Group: Applications/System
Summary: Gridsphere portal source code
Requires: APAC-apache-tomcat, APAC-apache-ant
%description devel
Installs the gridsphere source code

%files devel -f devel_files.list

%package docs
Group: Applications/System
Summary: Gridsphere portal documentation
Requires: APAC-gridsphere
%description docs
Installs the gridsphere documentation

%files docs -f doc_files.list
%defattr(-,tomcat,tomcat)

%changelog
* Thu Nov 16 2006 Andrew Sharpe
- changed name from gridsphere to APAC-gridsphere
* Tue Nov 14 2006 Andrew Sharpe
- separated into base, doc, devel packages
* Wed Jul 07 2006 Ashley Wright <a2.wright@qut.edu.au>
- Added checks for environment variables in %pre
- Manually source /etc/profile in %pre and %post
* Wed Jul 06 2006 Ashley Wright <a2.wright@qut.edu.au>
- Added apache-ant to requires.
- Some minor changes to script
* Wed May 03 2006 Matthew watts <mj.watts@qut.edu.au>
- Initial creation of spec file and rpm


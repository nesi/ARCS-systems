%define package_name gridportlets
%define PREFIX /usr/local

Summary: Gridportlets provides portlets that use globus
Name: APAC-%{package_name}
Version: 1.3.2
Release: 2
Copyright: GRIDSPHERE SOFTWARE LICENSE
Group: Applications/Internet
Source: %{package_name}-1.3.2-src.tgz
Patch: %{package_name}-1.3.2.patch
Requires: APAC-gridsphere
Buildrequires: APAC-gridsphere, APAC-gridsphere-devel
BuildRoot: /tmp/%{package_name}-buildroot
BuildArch: noarch

%description
Gridportlets

%prep
%setup -q -n %{package_name}
%patch -p1


%build
# pull in JAVA_HOME ANT_HOME CATALINA_HOME
source /etc/profile
export GRIDSPHERE_HOME="/usr/local/gridsphere"
ant jar

%install
rm -rf $RPM_BUILD_ROOT
source /etc/profile

export GRIDSPHERE_HOME="/usr/local/gridsphere"
export TOMCAT_HOME=$CATALINA_HOME
export CATALINA_HOME=${RPM_BUILD_ROOT}/tmp${CATALINA_HOME}

mkdir -p $RPM_BUILD_ROOT%{PREFIX}/%{package_name}
cp -a * $RPM_BUILD_ROOT%{PREFIX}/%{package_name}

# create file list
find . -path ./docs -prune -o -type f -print | sed -e "s|^\.|%{PREFIX}/%{package_name}|" > devel_files.list
find . -path ./docs -prune -o -type d -print | sed -e "s|^\.|%dir %{PREFIX}/%{package_name}|" >> devel_files.list


mkdir -p $RPM_BUILD_ROOT/tmp/usr/local
cp -a /usr/local/apache-tomcat $RPM_BUILD_ROOT/tmp/usr/local
find $RPM_BUILD_ROOT/tmp/usr/local/apache-tomcat -type f | sed -e "s|^$RPM_BUILD_ROOT/tmp||" | sort > pre_files.txt

# remove docs we don't need/want
rm -rf $RPM_BUILD_ROOT%{PREFIX}/%{package_name}/docs

ant install

# create file list
find $CATALINA_HOME -path $CATALINA_HOME/webapps/%{package_name}/docs -prune -o -type f -print | sed -e "s|^${RPM_BUILD_ROOT}/tmp||" | sort > files.txt

comm -2 -3 files.txt pre_files.txt > files.list

# this doesn't deal with empty parent directories
for i in $(cat files.list); do
	DIR=$(dirname $i)

	[[ "$DIR" =~ "%{PREFIX}/apache-tomcat/webapps/%{package_name}" ]] && \
			! grep -q "^%dir $DIR\$" files.list && \
			echo "%dir $DIR" >> files.list

	mkdir -p $RPM_BUILD_ROOT/$(dirname $i)
	cp $RPM_BUILD_ROOT/tmp/$i $RPM_BUILD_ROOT/$(dirname $i)
done

# add the main directory
echo "%dir %{PREFIX}/apache-tomcat/webapps/%{package_name}" >> files.list


# tone down logging
perl -pi -e "s|DEBUG|ERROR|g" $RPM_BUILD_ROOT$TOMCAT_HOME/webapps/%{package_name}/WEB-INF/classes/log4j.properties
#perl -pi -e "s|DEBUG|ERROR|g" $CATALINA_HOME/webapps/%{package_name}/WEB-INF/classes/log4j.properties


# fix database url
perl -pi -e "s|${RPM_BUILD_ROOT}/tmp||" $RPM_BUILD_ROOT$TOMCAT_HOME/webapps/%{package_name}/WEB-INF/persistence/hibernate.properties



# put back docs?
cp -a $CATALINA_HOME/webapps/%{package_name}/docs $RPM_BUILD_ROOT/$TOMCAT_HOME/webapps/%{package_name}


# cleanup
rm -rf $RPM_BUILD_ROOT/tmp


%clean
#rm -rf $RPM_BUILD_ROOT

%files -f files.list
%defattr(-,tomcat,tomcat)

%post
source /etc/profile
chown -R tomcat:tomcat $CATALINA_HOME/webapps/%{package_name}

%changelog

%package docs
Group: Applications/System
Summary: Gridsphere portal documentation
Requires: APAC-gridportlets
%description docs
Installs the gridportlets documentation

%files docs
%defattr(-,tomcat,tomcat)
/usr/local/apache-tomcat/webapps/%{package_name}/docs

%package devel
Group: Applications/System
Summary: Gridsphere portal source code
Requires: APAC-apache-tomcat, APAC-apache-ant
%description devel
Installs the gridportlets source code

%files devel -f devel_files.list



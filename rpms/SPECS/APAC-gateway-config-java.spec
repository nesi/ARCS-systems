Summary: Sets up java environment on login, ie JAVA_HOME and PATH
Name: APAC-gateway-config-java
Version: 0.1
Release: 4
License: APAC or JCU?
Group: Applications/Internet
#BuildRoot: /var/tmp/%{name}-buildroot
Requires: jdk
BuildArch: noarch

%description
Sets up java environment on login, ie JAVA_HOME and PATH

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/profile.d/

cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/java.sh
export JAVA_HOME="/usr/java/default"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

cat <<EOF > $RPM_BUILD_ROOT/etc/profile.d/java.csh
setenv JAVA_HOME "/usr/java/default"
setenv PATH "\$JAVA_HOME/bin:\$PATH"
EOF

# mkdir -p $RPM_BUILD_ROOT/usr/java
# ln -s /usr/java/jdk`rpm -qi jdk | awk '/^Version/ {print $3}'` $RPM_BUILD_ROOT/usr/java/current

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
%config /etc/profile.d/java.sh
%config /etc/profile.d/java.csh
# /usr/java/current

%post
mkdir -p /usr/local/lib/gridpulse
echo jdk >> /usr/local/lib/gridpulse/system_packages.pulse
if [ ! -h /usr/java/default ]; then ln -s /usr/java/jdk`rpm -qi jdk | awk '/^Version/ {print $3}'` /usr/java/default ; fi;

%postun
perl -ni -e "print unless /^jdk/;" /usr/local/lib/gridpulse/system_packages.pulse

%changelog
* Wed Nov 15 2006 Andrew Sharpe
- removed source


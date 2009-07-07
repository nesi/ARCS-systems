
install

### URL configurable options ###

# url (CentOS install location) [defaults to AARNET mirror]
# hostname [defaults to "ngsomething"]
# timezone ("Australia/Hobart") [no sensible default for this one...]
# network ("static" OR "&lt;ip&gt;/&lt;netmask&gt;/&lt;gateway&gt;/&lt;nameserver&gt;") [defaults to DHCP]
# lang [defaults to "en_AU"]
# keyboard [defaults to "us"]

url --url http://mirror.aarnet.edu.au/pub/centos/5/os/i386/
timezone --utc Australia/West
lang en_US
keyboard us
network --bootproto=dhcp --hostname=ngsomething

### End URL configured options ###

reboot
text
skipx
selinux --disabled
firewall --disabled

bootloader --location=mbr --driveorder=xvda --append="console=xvc0"
clearpart --all --drives=xvda
zerombr yes
part / --fstype ext3 --size=7168 --asprimary
part swap --size=1000 --asprimary

services --disable bluetooth,cpuspeed,gpm,irqbalance,lm_sensors,mcstrans,mdmonitor,microcode_ctl

%packages --nobase
anacron
compat-libstdc++-33
crontabs
gcc
gcc-c++
nfs-utils
ntp
openssl-devel
patch
portmap
postfix
sudo
vixie-cron
wget
which
xinetd
-sendmail
-selinux-policy-targeted

%post
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
wget -T 10 http://projects.arcs.org.au/dist/arcs.repo -O /etc/yum.repos.d/arcs.repo



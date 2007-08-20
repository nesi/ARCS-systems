#!/bin/sh
# BuildGuest.sh	Builds a bootable root filesystem on a mounted filesystem.
#		David Gwynne <dlg@itee.uq.edu.au>,
#		Graham Jenkins <graham@vpac.org>; Sep 2006. Rev: 20061214

# Check/display usage, create scratch directory and set trap
[ ! -d "$1" ]         && echo "Usage: `basename $0` /path/to/chroot" \
                      && echo " e.g.: `basename $0` /srv/vm1"        && exit 2
[ "`df -k $1 2>/dev/null | tail -1 | awk '{print $NF}'`" != "$1" ]   \
                      && echo "$1 should be a mount point!"          && exit 1
[ "$USER" != "root" ] && echo "You must be root!"                    && exit 1
CHROOT="$1"
DIR=`mktemp -d /tmp/yumstrap.XXXXXXXXXX`
[ ! -d "$DIR" ]       && echo "Unable to make temporary directory."  && exit 1
trap 'rm -rf $DIR' 0 1 2 3 13 15
YUMCONF="${DIR}/yum.conf"

# Build a composite repo file; need to eliminate gpgcheck kludge sometime
grep -v 'reposdir' /etc/yum.conf |  sed "s/gpgcheck=1/gpgcheck=0/"    > $YUMCONF
echo reposdir=\'\' >> $YUMCONF
RELEASEVER="`lsb_release -sr | cut -d. -f1`"
for i in /etc/yum.repos.d/*.repo; do
  sed -e"s/\$releasever/$RELEASEVER/" -e"s/gpgcheck=1/gpgcheck=0/" $i >>$YUMCONF
done

# Create essential directories and file, initiallise database and do the install
mkdir -p $CHROOT/{etc,dev,proc}
mkdir -p $CHROOT/var/lock/rpm
touch $CHROOT/var/lock/rpm/transaction
cat >$CHROOT/etc/fstab<<EOF
/dev/sda1               /                       ext3    defaults        1 1
none                    /dev/pts                devpts  gid=5,mode=620  0 0
none                    /dev/shm                tmpfs   defaults        0 0
none                    /proc                   proc    defaults        0 0
none                    /sys                    sysfs   defaults        0 0
/dev/sda2               swap                    swap    defaults        0 0
EOF
rpm --root=$CHROOT --initdb
! yum -y -c $YUMCONF --installroot=$CHROOT install yum                      \
  rootfiles bind-utils passwd dhclient vim-enhanced iptables ntp yp-tools   \
  mailx perl-DBI nss_ldap tcsh sudo lsof openssh-clients file which         \
  wget binutils patch bzip2 && echo "yum command FAILED; aborting!" && exit 1

# Copy modules, rename /lib/tls, create /etc/fstab, extend /etc/sysctl.conf
cd /lib/modules/`uname -r` && mkdir -p $CHROOT/lib/modules/`uname -r` &&    \
  find . -print | cpio -pdm $CHROOT/lib/modules/`uname -r`
mv $CHROOT/lib/tls $CHROOT/lib/tls.disabled
cat >>$CHROOT/etc/sysctl.conf<<EOF
vm.min_free_kbytes = 32768
xen.independent_wallclock = 1
EOF

# Basic networking
cat >$CHROOT/etc/hosts<<EOF
127.0.0.1               localhost.localdomain localhost
EOF
cat >$CHROOT/etc/sysconfig/network-scripts/ifcfg-eth0<<EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
EOF
cat >$CHROOT/etc/sysconfig/network<<EOF
NETWORKING=yes
EOF

# Essential devices
for i in console null zero ; do
  /sbin/MAKEDEV -d $CHROOT/dev -x $i
done 

# Passwd, unmount
echo "Please enter a root password (twice) for the new Guest machine .."
chroot $CHROOT passwd
echo "Unmounting: $CHROOT"
cd /tmp; umount $CHROOT/proc
umount $CHROOT && \
  echo "DONE! You should now be able to boot the new Guest machine!" && exit 0
echo "FAILED!"                                                       && exit 1

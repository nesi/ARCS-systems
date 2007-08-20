#!/bin/sh
# BuildGuest2.sh Builds a bootable filesystem on a mounted filesystem.
#		 Requires 2 parameters, 2nd of which names a yum.conf file.
#		 David Gwynne <dlg@itee.uq.edu.au>,
#		 Graham Jenkins <graham@vpac.org>; Sep 2006. Rev: 20061214
#
#		 Note: To make an RHEL3 filesystem on a more recent system,
#		 use:  mkfs -t ext3 -o none ..

# Check/display usage, create scratch directory, issue warning and set trap
[ \( ! -d "$1" \) -o \( ! -r "$2" \) ]                             \
         && echo "Usage: `basename $0` path-to-chroot conf-file "  \
         && echo " e.g.: `basename $0` /srv/vm1" /tmp/yum.SL3        && exit 2
[ "`df -k $1 2>/dev/null | tail -1 | awk '{print $NF}'`" != "$1" ] \
                      && echo "$1 should be a mount point!"          && exit 1
[ "$USER" != "root" ] && echo "You must be root!"                    && exit 1
CHROOT="$1"

# Create essential directories and files, initiallise database, do the install
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
for REPO in `echo repo list |yum shell|awk '{if($NF=="enabled")print $1}'`; do
  DISABLE="$DISABLE --disablerepo=$REPO"
done
yum -y -c $2 --installroot=$CHROOT $DISABLE install yum	# Force key retrieval 
! yum -y -c $2 --installroot=$CHROOT $DISABLE install yum                   \
  rootfiles bind-utils passwd dhclient vim-enhanced iptables ntp yp-tools   \
  mailx perl-DBI nss_ldap tcsh sudo lsof openssh-clients file which         \
  wget binutils patch bzip2 && echo "yum command FAILED; aborting!" && exit 1

# Copy yum.conf file if necessary
[ ! -f $CHROOT/etc/yum.conf ] && cp $2 $CHROOT/etc/yum.conf

# Copy modules, rename /lib/tls, create /etc/fstab, extend /etc/sysctl.conf
cd /lib/modules/`uname -r` && mkdir -p $CHROOT/lib/modules/`uname -r` &&    \
  find . -print | cpio -pdm $CHROOT/lib/modules/`uname -r`
mv $CHROOT/lib/tls $CHROOT/lib/tls.disabled
cat >>$CHROOT/etc/sysctl.conf<<EOF
vm.min_free_kbytes = 32768
xen.independent_wallclock = 1
EOF

# Hack /etc/inittab (requ'd for Scientific Linux 3 guests on Xen hosts)
awk '{if($NF!~"tty[2-6]$")print $0}'<$CHROOT/etc/inittab>/tmp/initt.$$ &&  \
  mv -f /tmp/initt.$$ $CHROOT/etc/inittab

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

#!/bin/bash
# Run as root!

if [ $EUID -ne 0 ]; then
    echo -e "$(tput setaf 1)[ERROR]$(tput sgr0) This script must be run as root!" 1>&2
    exit 1
fi

CHROOT_NAME=
CHROOT_USER=
DEBIAN_RELEASE=

usage() {
    echo "Usage: $0 [args]"
    echo
    echo "Args:"
    echo "-c : The name of the chroot jail."
    echo "-u : The name of the chroot user."
    echo "-r : The name of the Debian release that will be bootstrapped in the jail (i.e., wheezy, jessie, etc)."
    echo
}

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

while [ "$#" -gt 0 ]; do
    OPT="$1"
    case $OPT in
        -c) shift; CHROOT_NAME=$1 ;;
        -u) shift; CHROOT_USER=$1 ;;
        -r) shift; DEBIAN_RELEASE=$1 ;;
        -h) usage; exit 0 ;;
    esac
    shift
done

if [ -z $CHROOT_NAME ]; then
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) No chroot name specified."
    exit 1
fi

if [ -z $CHROOT_USER ]; then
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) No chroot user specified."
    exit 1
fi

if [ -z $DEBIAN_RELEASE ]; then
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) No debian release specified."
    exit 1
fi

echo "$(tput setaf 4)[INFO]$(tput sgr0) Installing the chroot will take several minutes."

# Dependencies.
apt-get install debootstrap schroot -y

# Create a config entry for the jail.
echo -e "[$CHROOT_NAME]\
\ndescription=Debian ($DEBIAN_RELEASE)\
\ntype=directory\
\ndirectory=/srv/chroot/$CHROOT_NAME\
\nusers=$CHROOT_USER\
\ngroups=sbuild\
\nroot-users=$CHROOT_USER\
\nroot-groups=root" > /etc/schroot/chroot.d/$CHROOT_NAME

# Specify the files that schroot will copy into the jail. These files MUST EXIST in the host environment!
# We're appending so as not to overwrite schroot's defaults!
echo -e "/etc/apt/sources.list\
\n/srv/setup_chroot.sh\
" >> /etc/schroot/default/copyfiles

# Don't mount the existing home dirs in the host environment!
# 1. I symlink my dotfiles into my home dir, and they break across filesystems.
# 2. I want a separate, untethered environment.
sed -i -r 's/^(\/home)/#\1/' /etc/schroot/default/fstab

# Create the dir where the jail is installed.
mkdir -p /srv/chroot/$CHROOT_NAME

# Finally, create the jail itself.
#debootstrap --no-check-gpg $DEBIAN_RELEASE /srv/chroot/$CHROOT_NAME file:///home/$CHROOT_USER/mnt
debootstrap $DEBIAN_RELEASE /srv/chroot/$CHROOT_NAME http://ftp.debian.org/debian

if [ $? -eq 0 ]; then
    # See /etc/schroot/default/copyfiles for files to be copied into the new chroot.
    echo "$(tput setaf 2)[SUCCESS]$(tput sgr0) Chroot installed in /srv/chroot/$CHROOT_NAME"
else
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) Something went terribly wrong." 1>&2
fi


#!/bin/bash
# Run as root!

set -eo pipefail

# TODO: Note that this assumes the chroot will be installed in /srv/chroot!

CHROOT_NAME=
CHROOT_USER=
DEBIAN_RELEASE=

ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
SUCCESS="$(tput setaf 2)[SUCCESS]$(tput sgr0)"

usage() {
    echo "Usage: $0 [args]"
    echo
    echo "Args:"
    echo "-c, --chroot   : The name of the chroot jail."
    echo "-u, --user     : The name of the chroot user."
    echo "-r, --release  : The name of the Debian release that will be bootstrapped in the jail:"
    echo "      - wheezy    (7)"
    echo "      - jessie    (8)"
    echo "      - stretch   (9)"
    echo "      - buster   (10)"
    echo "      - bullseye (11)"
    exit "$1"
}

if [ "$#" -eq 0 ]
then
    usage 1
fi

while [ "$#" -gt 0 ]
do
    OPT="$1"
    case $OPT in
        -c|--chroot) shift; CHROOT_NAME=$1 ;;
        -u|--user) shift; CHROOT_USER=$1 ;;
        -r|--release) shift; DEBIAN_RELEASE=$1 ;;
        -h|--help) usage 0 ;;
    esac
    shift
done

if [ $EUID -ne 0 ]
then
    echo -e "$ERROR This script must be run as root!" 1>&2
    exit 1
fi

if [ -z "$CHROOT_NAME" ] || [ -z "$CHROOT_USER" ] || [ -z "$DEBIAN_RELEASE" ]
then
    echo "$ERROR The CHROOT_NAME, CHROOT_USER and DEBIAN_RELEASE must all be specified." 1>&2
    exit 1
fi

echo "$INFO Installing the chroot can take several minutes depending on your system resources..."

# Dependencies.
echo "$INFO Installing debootstrap and schroot."
apt-get install debootstrap schroot -y

# Create a config entry for the jail.
echo "$INFO Installing schroot config."

echo -e "[$CHROOT_NAME]\
\ndescription=Debian ($DEBIAN_RELEASE)\
\ntype=directory\
\ndirectory=/srv/chroot/$CHROOT_NAME\
\nusers=$CHROOT_USER\
\ngroups=sbuild\
\nroot-users=$CHROOT_USER\
\nroot-groups=root" > "/etc/schroot/chroot.d/$CHROOT_NAME"

# Specify the files that schroot will copy into the jail on creation.
echo "/etc/apt/sources.list" >> /etc/schroot/default/copyfiles

# Don't mount the existing home dirs in the host environment!
# 1. Symlinked dotfiles break across filesystems.
# 2. Want a separate, untethered environment.
sed -i -r 's/^(\/home)/#\1/' /etc/schroot/default/fstab

# Create the dir where the jail is installed.
mkdir -p "/srv/chroot/$CHROOT_NAME"

# Finally, create the jail itself.
#debootstrap --no-check-gpg $DEBIAN_RELEASE /srv/chroot/$CHROOT_NAME file:///home/$CHROOT_USER/mnt
if debootstrap "$DEBIAN_RELEASE" "/srv/chroot/$CHROOT_NAME" http://ftp.debian.org/debian
then
    # See /etc/schroot/default/copyfiles for files to be copied into the new chroot.
    echo "$SUCCESS Chroot installed in /srv/chroot/$CHROOT_NAME!"
    echo "$INFO You can now enter the chroot by issuing the following command:"
    echo -e "\n\tschroot -u $CHROOT_USER -c $CHROOT_NAME\n"
    echo Have fun! Weeeeeeeeeeeee
else
    echo "$ERROR Something went terribly wrong!" 1>&2
    echo "$ERROR Are you trying to overwrite an existing chroot?" 1>&2
fi


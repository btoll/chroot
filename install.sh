#!/bin/bash

set -euo pipefail

ERROR="$(tput setaf 3)[$0]$(tput setaf 1)[ERROR]$(tput sgr0)"
INFO="$(tput setaf 3)[$0]$(tput setaf 4)[INFO]$(tput sgr0)"
SUCCESS="$(tput setaf 3)[$0]$(tput setaf 2)[SUCCESS]$(tput sgr0)"

if [ $EUID -ne 0 ]
then
    echo -e "$ERROR This script must be run as root!" 1>&2
    exit 1
fi

echo "$INFO Installing debootstrap and schroot, if missing."
DEPS=(
    debootstrap
    schroot
)

for dep in "${DEPS[@]}"
do
    if ! command -v "$dep" > /dev/null
    then
        echo "$INFO Installing missing dependency \`$dep\`."
        apt-get install --no-install-recommends --yes "$dep"
    fi
done

if ! command -v tput > /dev/null
then
    echo "$INFO Installing missing dependency \`$dep\`."
    apt-get install --no-install-recommends --yes ncurses-bin
fi

ARCH=amd64
CHROOT_DIR=
CHROOT_GROUP=
CHROOT_NAME=
CHROOT_USER=
DEBIAN_RELEASE=
DRY_RUN=false
PERSONALITY=linux
PROFILE=
TYPE=plain

usage() {
    echo "Usage: $0 [args]"
    echo
    echo "Args:"
    echo "-c, --chroot   : The name of the chroot jail."
    echo "-d, --dir      : The directory in which to install the chroot (defaults to /srv/chroot)."
    echo "-t, --type     : The name of the type of the chroot. Defaults to 'plain'."
    echo "-u, --user     : The name of the chroot user. Must be a user on the host machine."
    echo "-g, --group    : The name of the chroot group. Must be a group on the host machine."
    echo "-p, --profile  : The name of the profile. See the README for more information."
    echo "-r, --release  : The Debian release that will be bootstrapped in the jail:"
    echo "      - jessie     (8)"
    echo "      - stretch    (9)"
    echo "      - buster    (10)"
    echo "      - bullseye  (11)"
    echo "      - bookworm  (12)"
    echo "--32           : Set this flag if the chroot is to be 32-bit on a 64-bit system."
    echo "--dry-run      : Write the config to STDOUT and exit (will not run the program)."
    echo "-h, --help     : Show usage."
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
        --32) PERSONALITY=linux32 ;;
        -c|--chroot) shift; CHROOT_NAME=$1 ;;
        -d|--dir) shift; CHROOT_DIR=$1 ;;
        --dry-run) DRY_RUN=true ;;
        -g|--group) shift; CHROOT_GROUP=$1 ;;
        -h|--help) usage 0 ;;
        -p|--profile) shift; PROFILE=$1 ;;
        -r|--release) shift; DEBIAN_RELEASE=$1 ;;
        -t|--type) shift; TYPE=$1 ;;
        -u|--user) shift; CHROOT_USER=$1 ;;
    esac
    shift
done

if [ -z "$CHROOT_NAME" ] || [ -z "$DEBIAN_RELEASE" ]
then
    echo "$ERROR The CHROOT_NAME and the DEBIAN_RELEASE must be specified." 1>&2
    exit 1
fi

if [ -z "$CHROOT_USER" ] && [ -z "$CHROOT_GROUP" ]
then
    echo "$ERROR The CHROOT_USER or the CHROOT_GROUP must be specified." 1>&2
    exit 1
fi

if [ -z "$CHROOT_DIR" ]
then
    CHROOT_DIR="$(pwd)/$CHROOT_NAME"
    echo "$INFO \`--dir\` not set, defaulting to $CHROOT_DIR (the current working directory + the chroot name)."
fi

CONFIG="[$CHROOT_NAME]\
\ndescription=Debian ($DEBIAN_RELEASE)\
\ntype=$TYPE\
\ndirectory=$CHROOT_DIR\
\npersonality=$PERSONALITY\
\nprofile=$PROFILE\
\nusers=$CHROOT_USER\
\nroot-users=$CHROOT_USER\
\ngroups=$CHROOT_GROUP\
\nroot-groups=$CHROOT_GROUP"

if "$DRY_RUN"
then
    echo -e "$CONFIG"
    exit 0
fi

echo "$INFO Installing the chroot to $CHROOT_DIR.  This can take \"a while\" depending on your system resources..."

# Create a config entry for the jail.
echo "$INFO Installing schroot config to /etc/schroot/chroot.d/$CHROOT_NAME."

# Note that "plain" schroot types (the default) don't run setup scripts and mount filesystems.
echo -e "$CONFIG" > "/etc/schroot/chroot.d/$CHROOT_NAME"

# Create the dir where the jail is installed.
mkdir -p "$CHROOT_DIR"

# Finally, create the jail itself.
#debootstrap --no-check-gpg $DEBIAN_RELEASE /srv/chroot/$CHROOT_NAME file:///home/$CHROOT_USER/mnt
if debootstrap \
    --arch="$ARCH" \
    --variant=minbase \
    "$DEBIAN_RELEASE" "$CHROOT_DIR" http://deb.debian.org/debian
then
    # See /etc/schroot/default/copyfiles for files to be copied into the new chroot.
    echo "$SUCCESS Chroot installed in $CHROOT_DIR!"
    echo "$INFO You can now enter the chroot by issuing the following command:"
    # If only the `--group` was given and no `--user`, use "USERNAME" as a placeholder.
    echo -e "\n\tschroot -u ${CHROOT_USER:-USERNAME} -c $CHROOT_NAME -d /\n"
    echo Have fun! Weeeeeeeeeeeee
else
    echo "$ERROR Something went terribly wrong!" 1>&2
    echo "$ERROR Are you trying to overwrite an existing chroot?" 1>&2
fi


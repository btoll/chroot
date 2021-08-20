#!/bin/bash

set -euo pipefail

if [ $EUID -ne 0 ]
then
    echo -e "$(tput setaf 1)[ERROR]$(tput sgr0) This script must be run as root!" 1>&2
    exit 1
fi

if [ "$#" -eq 0 ]
then
    echo "Usage: $0 username"
    exit 1
fi

ADDUSER="$1"

# Bug workaround.
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=705752
# http://askubuntu.com/questions/335538/unknown-user-in-statoverride-file
sed -i '/crontab/d' /var/lib/dpkg/statoverride

apt-get update
# Have schroot install these packages?
apt-get install build-essential curl git tmux vim -y

# Yes, I know I could have schroot mount the home dirs, but I don't want it to (and see comment in ./install.sh)!
if echo -e "asdf\nasdf\n$ADDUSER\n\n\n\n\n" | adduser "$ADDUSER"
then
    echo -e "\n$(tput setaf 4)[INFO]$(tput sgr0) Added user $ADDUSER"
elif [ ! -d "/home/$ADDUSER" ]
then
    # If the user already exists but the homedir doesn't, create it.
    # If the dir doesn't exist, it's because the user was auto-created via schroot config or by some other means.
    echo -e "\n$(tput setaf 4)[INFO]$(tput sgr0) Creating home directory"
    mkdir "/home/$ADDUSER"
fi

pushd "/home/$ADDUSER"
git clone https://github.com/btoll/dotfiles.git
cp dotfiles/minimal/.* .
echo -e "\n$(tput setaf 4)[INFO]$(tput sgr0) Installed dotfiles"
popd

if chown -R "$ADDUSER:$ADDUSER" "/home/$ADDUSER"
then
    echo "$(tput setaf 2)[SUCCESS]$(tput sgr0) Setup completed."
else
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) Something went terribly wrong."
fi


# Installing chroot

- Installs Debian, currently:
    + jessie    (8)
    + stretch   (9)
    + buster   (10)
    + bullseye (11)

## Dependencies

- [debootstrap]
- [schroot]

## Establish and bootstrap chroot jail

Run `install.sh`.

The script will do the following:

- Install debootstrap and schroot.
- Create the following chroot definition in `/etc/schroot/chroot.d/$CHROOT_NAME`:

    For example, let's do a dry run of the following command:

    ```
    sudo ./install.sh \
    > --chroot onion \
    > --group sudo \
    > --release bullseye \
    > --type directory \
    > --profile minimal \
    > --dry-run
    ```

    This will produce the following chroot config:

    ```
    [onion]
    description=Debian (bullseye)
    type=directory
    directory=/srv/chroot/onion
    personality=linux
    profile=minimal
    users=
    root-users=
    groups=sudo
    root-groups=sudo
    ```

    If the command is run again without the `--dry-run` flag, it will install this configuration to `/etc/schroot/chroot.d/onion` and proceed to create the chroot.

- Create the jail in `$CHROOT_DIR` (defaults to `/srv/chroot`). It does this by downloading the version of Debian specified on the command line from `http://deb.debian.org/debian`.

> Make sure to read the [schroot(1)] and [schroot.conf(5)] man pages!  I've left out a lot of detail here!

That's it, you're done!  You can now change (root) to your new chroot by issuing the following commmand:

    schroot --directory / -u $CHROOT_USER -c $CHROOT_NAME

[debootstrap]: https://packages.debian.org/stretch/debootstrap
[schroot]: https://packages.debian.org/stretch/schroot
[schroot(1)]: https://manpages.debian.org/stretch/schroot/schroot.1.en.html
[schroot.conf(5)]: https://manpages.debian.org/stretch/schroot/schroot.conf.5.en.html
[build-essential]: https://packages.debian.org/stretch/build-essential
[dotfiles]: https://github.com/btoll/dotfiles/tree/master/minimal


# Installing chroot

- Installs Debian

## Dependencies

- [debootstrap]
- [schroot]

## Establish and bootstrap chroot jail

Run `install.sh`.

The script will do the following:

- Install debootstrap and schroot.
- Create the following chroot definition in `/etc/schroot/chroot.d/$CHROOT_NAME`:

```
[$CHROOT_NAME]
description=Debian ($DEBIAN_RELEASE)
type=directory
directory=/srv/chroot/$CHROOT_NAME
users=$CHROOT_USER
groups=sbuild
root-users=$CHROOT_USER
root-groups=root
```

- Append the following file(s) to `/etc/schroot/default/copyfiles` which will then be copied into the jail (note these files must exist in the host environment):

```
/etc/apt/sources.list
```

- Comment-out the `/home` mount point in `/etc/schroot/default/fstab`. I don't want `/home` mounted because:
    + I symlink my dotfiles into my home dir, and they break across filesystems.
    + I want a separate, untethered environment.

- Create the jail in `/srv/chroot/$CHROOT_NAME`. It does this by downloading the version of Debian specified on the command line from `http://ftp.debian.org/debian`.

    Note that if you're bandwidth-impaired like me, you can create the chroot by pointing `debootstrap` to a mounted image.

    For example:

        mkdir foo
        mount debian_image.iso foo
        debootstrap stretch /srv/chroot/test file:///usr/local/src/iso/debian/free/foo

    If you get an error message about GPG, add the `--no-check-gpg` flag to the `debootstrap` command.

> Make sure to read the [schroot(1)] and [schroot.conf(5)] man pages!  I've left out a lot of detail here!
>
> For example, I'm configuring the files in `/etc/schroot/default/` because I've specified `directory` as the chroot type in the config in the `install.sh` script. If you provide your own chroot config with a different `type` value, you'll have to alter the scripts in a different dir under `/etc/schroot`.

That's it, you're done!  You can now change (root) to your new chroot by issuing the following commmand:

    schroot -u $CHROOT_USER -c $CHROOT_NAME

> Note that if `proc` and `dev/pts` aren't mounted in the chroot, you will not have a `pty` when logging in.  `tmux` and other programs will appear not to launch, and when running the `tty` program, you'll be told `not a tty`.
> To fix this, run `mnt/chroot_mounts.sh` (and its brother `mnt/chroot_umounts.sh`) in the host environment.

The rest of this document describes optional chroot environment configurations and notes.

# Codesharing

1. Configure chroot

    Run `env/codeshare.sh`.

    The script will do the following:

    - Install [build-essential] (gcc, make, etc.), curl, git, tmux and vim.
    - Add the user given on the CLI.
    - Clone my minimal dotfiles into the new home dir:
        + [dotfiles]

2. Configure SSH

    Add the directive to `sshd_config` that will automatically jail an SSH remote login to the new chroot. Note that you should add this to the `ssdh_config` in the host environment, NOT the chroot jail.

    ```
    Match group codeshare
            ChrootDirectory /srv/chroot/$CHROOT_NAME
            X11Forwarding no
            AllowTcpForwarding no
    ```

# Notes

### Installing NodeJS

The NodeJS tarball uses the `xz` compression tool:

- sudo apt-get install xz-utils
- tar xvJf xxx.xz

#### If getting a "No such file or directory" error when executing the node binary...

The node binary is a 32-bit ELF but it's a 64 bit OS.

The following commands will provide more information:

```
file /path/to/node
ldd /path/to/node
```

https://superuser.com/questions/344533/no-such-file-or-directory-error-in-bash-but-the-file-exists

tl;dr:

```
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --reinstall libc6-i386
sudo apt-get install "libstdc++6:i386"
```

In this example, all users that should be jailed upon remote login should belong to the `codeshare` group.

[debootstrap]: https://packages.debian.org/stretch/debootstrap
[schroot]: https://packages.debian.org/stretch/schroot
[schroot(1)]: https://manpages.debian.org/stretch/schroot/schroot.1.en.html
[schroot.conf(5)]: https://manpages.debian.org/stretch/schroot/schroot.conf.5.en.html
[build-essential]: https://packages.debian.org/stretch/build-essential
[dotfiles]: https://github.com/btoll/dotfiles/tree/master/minimal


# Installing chroot

- Installs Debian

## Dependencies

- [debootstrap]
- [schroot]

## Establish and bootstrap chroot jail

Run `install_chroot.sh`.

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

- Append the following files to `/etc/schroot/default/copyfiles` which will then be copied into the jail (note these files must exist in the host environment):

```
/etc/apt/sources.list
/srv/setup_chroot.sh
```

- Comment-out the `/home` mount point in `/etc/schroot/default/fstab`. I don't want `/home` mounted because:
    + I symlink my dotfiles into my home dir, and they break across filesystems.
    + I want a separate, untethered environment.

- Create the jail in `/srv/chroot/$CHROOT_NAME`.

> Make sure to read the [schroot(1)] and [schroot.conf(5)] man pages!  I've left out a lot of detail here, as this is meant
> to be a quick overview to jog the memory of Future Me.
>
> For example, I'm configuring the files in `/etc/schroot/default/` because I've specified `directory` as the chroot
> type in the config in the `install_chroot.sh` script. If you provide your own chroot config with a different `type`
> value, you'll have to alter the scripts in a different dir under `/etc/schroot`.

# Configuring chroot

Run `setup_chroot.sh`.

The script will do the following:

- Install [build-essential] (gcc, make, etc.), curl, git, tmux and vim.
- Add the user given on the CLI.
- Clone my minimal dotfiles into the new home dir:
    + [dotfiles]

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

# SSH

Add the directive to `sshd_config` that will automatically jail an SSH remote login to the new chroot. Note that you should add this to the `ssdh_config` in the host environment, NOT the chroot jail.

```
Match group codeshare
        ChrootDirectory /srv/chroot/derp
        X11Forwarding no
        AllowTcpForwarding no
```

In this example, all users that should be jailed upon remote login should belong to the `codeshare` group.

# Filesystem mounts

If `proc` and `dev/pts` aren't mounted, you will not have a `pty` when logging in.  `tmux` and other programs will appear not to launch.  You can run the `tty` program, at which point you'll be told `not a tty`.

To fix this, run `chroot_mounts.sh` in the host environment.

[debootstrap]: https://packages.debian.org/jessie/debootstrap
[schroot]: https://packages.debian.org/jessie/schroot
[schroot(1)]: https://manpages.debian.org/jessie/schroot/schroot.1.en.html
[schroot.conf(5)]: https://manpages.debian.org/jessie/schroot/schroot.conf.5.en.html
[build-essential]: https://packages.debian.org/jessie/build-essential
[dotfiles]: https://github.com/btoll/dotfiles/tree/master/minimal


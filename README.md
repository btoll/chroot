# `chroot`

## What's this all about?

Install a minimal Debian build in a `chroot` environment!

Here's a fine article that is a gripping read!  [On Running a Tor Onion Service in a Chroot](https://www.benjamintoll.com/2021/08/20/on-running-a-tor-onion-service-in-a-chroot/)

## Version support

- jessie (8)
- stretch (9)
- buster (10)
- bullseye (11)

## Dependencies

- [debootstrap]
- [schroot]

## Usage

```
Usage: ./install.sh [args]

Args:
-c, --chroot   : The name of the chroot jail.
-d, --dir      : The directory in which to install the chroot (defaults to /srv/chroot).
-t, --type     : The name of the type of the chroot. Defaults to 'plain'.
-u, --user     : The name of the chroot user. Must be a user on the host machine.
-g, --group    : The name of the chroot group. Must be a group on the host machine.
-p, --profile  : The name of the chroot group. Must be a group on the host machine.
-r, --release  : The Debian release that will be bootstrapped in the jail:
      - jessie    (8)
      - stretch   (9)
      - buster   (10)
      - bullseye (11)
--32           : Set this flag if the chroot is to be 32-bit on a 64-bit system.
--dry-run      : Write the config to STDOUT and exit (will not run the program).
-h, --help     : Show usage.
```

**Q.** What happens if the user and/or group provided isn't one on the host system?

**A.** You'll be locked out!

## `schroot` options

The `schroot` definitions are placed in `/etc/schroot/chroot.d` by default.  They are simple [INI files], and I'll briefly describe only the key/value pairs that the wrapper tool uses (there are others).

> Note that not all of the keys in the `chroot` definition below (i.e., what is written as an INI file to `/etc/schroot/chroot.d/$CHROOT_NAME` maps to a configurable option in the wrapper tool.
>
> For example, there are currently CLI arguments for `personality`, `root-user` and `group-user`, et al, but values for those keys may be set depending upon other CLI arguments.
>
> Read the docs and view the shell script code, it's easy to follow and understand!

Some definitions are taken directly from the [schroot.conf(5)] man page.

- `description`
    + A short description of the chroot. This may be localised for different languages.
    + It builds its value from `--release`:

            description=Debian ($DEBIAN_RELEASE)

- `type`
    + The type of the chroot. Valid types are 'plain', 'directory', 'file', 'loopback', 'block-device', 'btrfs-snapshot' and 'lvm-snapshot'. If empty or omitted, the default type is 'plain'. Note that 'plain' chroots do not run setup scripts and mount filesystems; 'directory' is recommended for normal use.
    + Defaults to 'plain'. Change to another `type` if wanting to run setup scripts and mount filesystems, which can be specified as the value to the `profile` key.

- `directory`
    + The directory containing the chroot environment. This is where the root will be changed to when executing a login shell or a command.
    + The directory must exist and have read and execute permissions to allow users access to it. Note that on Linux systems it will be bind-mounted elsewhere for use as a chroot; the directory for 'plain' chroots is mounted with the --rbind option to [mount(8)], while for 'directory' chroots --bind is used instead so that sub-mounts are not preserved (they should be set in the fstab file just like in `/etc/fstab` on the host).
    + This option is mandatory when used with 'plain' and 'directory' types, which are the only types that the wrapper tool uses.

- `personality`
    + Set the personality (process execution domain) to use. This option is useful when using a 32-bit chroot on 64-bit system, for example. The default value is 'linux'. For a 32-bit chroot on a 64-bit system, 'linux32' is the option required.
    + Defaults to 'linux'.  Changes the value to 'linux32' if the '--32' flag is present.

- `profile`
    + References one of the default directories inside `/etc/schroot`:
        - `buildd`
        - `default`
        - `desktop`
        - `minimal`
        - `sbuild`
    + Each of these contain three files:
        - `copyfiles`
            + A file containing a list of files to copy into the chroot (one file per line). The file will have the same absolute location inside the chroot.
        - `fstab`
            + The filesystem table file to be used to mount filesystems within the chroot. The format of this file is the same as for `/etc/fstab`, documented in [fstab(5)].
            + The only difference is that the mountpoint path `fs_dir` is relative to the chroot, rather than the root. Also note that mountpoints are canonicalised on the host, which will ensure that absolute symlinks point inside the chroot, but complex paths containing multiple symlinks may be resolved incorrectly; it is inadvisable to use nested symlinks as mountpoints.
        - `nssdatabases`
            + A file listing the system databases to copy into the chroot. The default databases are 'passwd', 'shadow', 'group' and 'gshadow'. Other potential databases which could be added include 'services', 'protocols', 'networks', and 'hosts'. The databases are copied using [getent(1)] so all database sources listed in `/etc/nsswitch.conf` will be used for each database.

- `users`
    + The user that is allowed access to the `chroot`.  It must be an existing user on the host or access will be denied.
    + If empty or omitted, no users will be allowed access (unless a group they belong to is also specified in groups).

- `root-users`
    + The user who is allowed password-less access to the `chroot`.
    + If empty or omitted, no users will be allowed root access without a password (but if a user or a group they belong to is in users or groups, respectively, they may gain access with a password).

- `groups`
    + The group whose members are allowed access to the `chroot`.  If empty or omitted, no groups of users will be allowed access.

- `root-groups`
    + The groups whose users are allowed password-less access to the `chroot`.
    + If empty or omitted, no users will be allowed root access without a password (but if a user or a group they belong to is in users or groups, respectively, they may gain access with a password).

Please read the [schroot.conf(5)] man page for complete coverage of all of the `schroot` options.

> The wrapper tool only uses a subset of the options that `schroot` makes available.  If you need more, then your use case perhaps exceeds what this script is trying to accomplish, which is to get a `chroot` bootstrapped quickly for general use cases.

## `schroot` profiles

`schroot` profiles are a nice feature that allows `chroot`s to have more or less bootstrapped on creation.  It controls the files that are copied from the host, what filesystems are mounted and which system databases (like `/etc/passwd`) to copy into the `chroot` from the host.

For example, to have a minimum `chroot` environment with just the base OS, use the 'plain' `type` (`type=plain`), or omit it as it's the default.  This value doesn't trigger `schroot` to copy any files or mount any filesystems into the `chroot` environment.

Another example is that of `type=directory` which has `schroot` copy files and mount filesystems into the host.  The only question that remains is which `profile` will be used as the template.

This is important as it will expose more of the host into the `chroot` environment.  For example, a nice configuration for running a web server is to use `type=directory` and `profile=minimal`, which, as its name implies, will only mount two filesystems (one being `/proc`) and copy a conservative number of files and databases into the `chroot`.

There are other profiles, such as `desktop`, which are more liberal in what they copy and mount, and may serve other use cases quite well.

Though perhaps not technically accurate, I think of `type=directory` as "turning on" the ability to copy files and mount filesystems and of profiles as a use case, which may or may not fit your project.

> Although `schroot` supports the use of custom scripts, the wrapper tool (currently) does not.

## Create the `chroot`

Run `install.sh`.

The script will do the following:

- Install debootstrap and schroot.
- Create the following chroot definition in `/etc/schroot/chroot.d/$CHROOT_NAME`:

    For example, let's do a dry run of the following command:

    ```
    sudo ./install.sh \
    --chroot onion \
    --group sudo \
    --release bullseye \
    --type directory \
    --profile minimal \
    --dry-run
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
[INI files]: https://en.wikipedia.org/wiki/INI_file
[schroot(1)]: https://manpages.debian.org/stretch/schroot/schroot.1.en.html
[schroot.conf(5)]: https://manpages.debian.org/stretch/schroot/schroot.conf.5.en.html
[mount(8)]: https://www.man7.org/linux/man-pages/man8/mount.8.html
[fstab(5)]: https://www.man7.org/linux/man-pages/man5/fstab.5.html
[getent(1)]: https://www.man7.org/linux/man-pages/man1/getent.1.html


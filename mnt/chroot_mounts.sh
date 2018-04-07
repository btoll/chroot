#!/bin/bash

mount -t proc proc /srv/chroot/codeshare/proc
mount -t sysfs sys /srv/chroot/codeshare/sys
mount -o bind /dev /srv/chroot/codeshare/dev
mount -t devpts devpts /srv/chroot/codeshare/dev/pts


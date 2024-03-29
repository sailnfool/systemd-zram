Systemd zRAM service
--------------------

Use a part of your RAM as compressed swap.


[`zram`](https://en.wikipedia.org/wiki/Zram) is a Linux kernel feature
that provides a form of virtual memory compression. `zram` module increases
performance by avoiding paging to disk and using a compressed block device in
RAM instead, inside which paging takes place until it is necessary to use the
swap space on a hard disk drive. Since using `zram` is an alternative way to
provide swapping on RAM, `zram` allows Linux to make a better use of RAM when
swapping/paging is required, especially on older computers with less RAM
installed.  It also eliminates wear on a microSD used in a Raspberry Pi by
moving swap space off of the flash memory and into RAM.

See also:
https://www.kernel.org/doc/Documentation/blockdev/zram.txt

***REN ***  Contrary to the above documents - the zram device is NOT
automatically provided in all kernels.  This version of systemd-zram
addresses this issue:

*** REN *** With the Ubuntu 21.10 release, Ubuntu removed the zram module
and it must be installed with linux-modules-extra-raspi.  There was
also a recent article in "Make Use of" pointed out that there is also
a way to enable the swapping feature on a Raspberry PI by adding
the line "zswap.enable=1" to the end of /boot/firmware/cmdline.txt
This program provides a systemd service to automatically load and configure
such module at system boot.
# https://github.com/ecdye/zram-config/issues/71
# https://www.makeuseof.com/boost-ubuntu-performance-on-raspberry-pi-4/

You can choose compression algorithm by editing systemd service.
To see available algorithms do `cat /sys/block/zram0/comp_algorithm`.

You can choose to have systems with less then 1GB of RAM to have up
to 2 * the ram space used for zram swap.  Edit the systemd service to
say yes|no


Installation
------------

You can choose between different installation methods. Note that uninstallation
doesn't remove active zram disk(s).

### Classic method ###

- Build and install:

        $ make
        # sudo make install

- Uninstall:

        # sudo make uninstall

### Debian package ###

- Build and install:

        $ make debian_pkg
        # sudo dpkg -i systemd-zram_*.deb

- Uninstall:

        # apt purge systemd-zram


### Arch Linux package

- Build and install:

        $ make arch_pkg
        # sudo pacman -U systemd-zram-*.pkg.tar.xz

Alternatively you can install it from AUR:

        $ trizen -S systemd-zram

- Uninstall:

        # sudo pacman -Rsc systemd-zram


Usage
-----

To start the service execute as root:

        # sudo systemctl start systemd-zram

To stop it:

        # sudo systemctl stop systemd-zram

If you want to enable zram at boot, just run as root:

        # sudo systemctl enable systemd-zram

And for disable it at boot:

        # sudo systemctl disable systemd-zram



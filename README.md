# rpi-auto-setup-script
Interactively setup a raspberry pi's micro SD card

I got tired of having to manually setup wifi and SSH on my raspberry pi whenever the SD card got corrupted when there was a power outage, or when a package got broken and I couldn't completely fix it, so I made this script to setup the microSD card automatically, interactively inputting wifi name and password, and whether to setup SSH

this needs the IMG file to be next to the script (or at least, in a directory under the same directory where the script is, the script uses `find`)

so

```
tree
.
├── 2020-02-13-raspbian-buster-lite.img
└── setup.sh

0 directories, 2 files
```

tested with raspbian buster `2020-02-13-raspbian-buster-lite.img`

```
sha256sum 2020-02-13-raspbian-buster-lite.img
4700d93867eed0b047494d381590a1901a32b2c0f8d95d8d45d6e63fb8c46969  2020-02-13-raspbian-buster-lite.img
```

```
$ shellcheck --version
ShellCheck - shell script analysis tool
version: 0.7.1
license: GNU General Public License, version 3
website: https://www.shellcheck.net
```

shellcheck doesn't show any problems, though I think it could maybe be improved, this serves my purposes

## dependencies

list of programs that might not be installed on your system, if on Arch Linux, install with `sudo pacman -S <pkg-name>`, if on Debian/Ubuntu install with `sudo apt-get install <pkg-name>` (for this I recommend adding the `--no-install-recommends` flag)

```
fzy # for interactive choice
dd # to flash de micro SD card
wpa_passphrase # to setup the wpa_supplicant.conf for wifi
lsblk # to list drives/sd cards
```

## features

- when prompted to choose a drive, you can input `None` (or any other invalid value) to abort, and insert the microSD card you intend to use with your Raspberry Pi
- when prompted for passwords, no echo (that is, they aren't written to the shell)

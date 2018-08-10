# AIS
Archlinux install script. Mostly targeted on EFI systems.

## How to use
This script was made only for my personal use. If you really want to try it, follow this:
1. Boot Arch live media
2. `pacman -Syy && pacman -Sdd git`
3. `git clone https://github.com/Iheiko/AIS`
4. `cd AIS && chmod a+x *.sh`
5. `./install.sh`

## Troubleshooting
1. If you encounter something like this:
```
 error: Partition / too full: 88218 blocks needed, 62335 blocks are free
```
Then you should resize your cowspace to, at least, 512Mb: `mount -o remount,size=512M /run/archiso/cowspace`

2. VBox crashes after writing partition table.

Change your vdisk format to vdi.

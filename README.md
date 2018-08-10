# AIS
Just a regular script to install Archlinux. Mostly targeted on VirtualBox with EFI.

## How to use
This script was made only for my personal use. If you really want to try it, follow this:
1. Make sure you have enabled EFI in your VBox settings(Settings -> System -> Motherboard -> Enable EFI).
2. Boot Arch live media
3. `pacman -Syy && pacman -Sdd git`
4. `git clone https://github.com/Iheiko/AIS`
5. `cd AIS && chmod a+x *.sh`
6. `./install.sh`
7. Reboot

## Troubleshooting
1. If you encounter something like this:
```
error: Partition / too full: 88218 blocks needed, 62335 blocks are free
```
Then you should resize your cowspace to, at least, 512Mb:
`mount -o remount,size=512M /run/archiso/cowspace`

2. VBox crashes after writing partition table.

Change your vdisk format to vdi.

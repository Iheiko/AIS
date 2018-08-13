# AIS
Archlinux install script. EFI installation only.

## How to get
### Using git
1. Boot Arch live media
2. `pacman -Sy && pacman -Sdd git`
3. `git clone https://github.com/Iheiko/AIS`
4. `cd AIS`
5. `./install.sh`

### Using pacman
1. Boot Arch live media
2. `wget -O install https://git.io/ais020`
3. `pacman -U install`
4. `rehash`
5. `install.sh`

## How to use
```
Usage: ./install.sh (-d <Disk> | -m -r <Partition> -e <Partition>) [OPTIONS] 
Required:
    -d|--disk      <Disk>        Specify disk for automated partition creation installation.
    -m|--manual                  For manual partition selection. --disk will be ignored.
    -r|--root      <Partition>   Root partition(/). Only needed if --manual
    -e|--esp       <Partition>   EFI system partiton. Only needed if --manual

Options:
    -h|--help                    Print this message
    -c|--country   <Country>     Country for mirrorlist priority. Default: None
    -p|--pkg-list  <Package ...> Additional packages to install
    -t|--timezone  <Region/City> Specify timezone. Default:"UTC"
    -H|--hostname  <Hostname>    Hostname for installed system. Default:"Arch"
    --with-swap    <Size>        Swap of <Size> will be created. Works only with --disk.
    -s|--swap      <Partition>   Use partition as swap. Works only with --manual
    --bootloader   <Bootloader>  grub or systemd-boot. Default:"systemd-boot"
```

## Troubleshooting
1. If you encounter something like this:
```
 error: Partition / too full: 88218 blocks needed, 62335 blocks are free
```
Then you should resize your cowspace to, at least, 512Mb: `mount -o remount,size=512M /run/archiso/cowspace`

2. VBox crashes after writing partition table.

Change your vdisk format to vdi.

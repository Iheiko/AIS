#!/bin/bash
#
# Main install script

PWD="${0%/*}"
DISK=/dev/sda
COUNTRY="Russia"
PKG_LIST=""
MANUAL=""
ROOT=""
ESP=""


usage() {
echo "Usage: $0 -d <Disk> [-hdcptHm]
Options:
    -h|--help                    print this message
    -d|--disk      <Disk>        Specify disk for installation. Default:\"/dev/sda\"
    -c|--country   <Country>     Select country for mirrolist priority. Default: None
    -p|--pkg-list  <Package ...> Additional packages to install
    -t|--timezone  <Region/City> Specify timezone Default:\"UTC\"
    -H|--hostname  <Hostname>    Hostname for installed system Default:\"Arch\"
    -m|--manual                  For manual partition select. --disk will be ignored.
    -r|--root                    Root partition(/). Only needed if --manual
    -e|--esp                     EFI system partiton. Only needed if --manual
    "
}
format_part() {
    local root=${1}
    local esp=${2}
    yes y | mkfs.vfat $esp
    yes y | mkfs.ext4 $root
}

make_part() {
    local disk=${1}
    printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk ${disk}
}
mount_part() {
    local root=${1}
    local esp=${2}
    mount ${root} /mnt
    mkdir /mnt/boot
    mount ${esp} /mnt/boot
}
mirrorlist() {
    local country=${1}
    cat <(grep ${country} -A1 /etc/pacman.d/mirrorlist) \
        <(grep -v ${country} -A1 /etc/pacman.d/mirrorlist) \
        | sed -e 's/--//g' > .mirrorlist.tmp
    mv .mirrorlist.tmp /etc/pacman.d/mirrorlist
}
run_chrooted() {
    cp ${PWD}/chrooted.sh /mnt/root/chrooted.sh
    chmod a+x /mnt/root/chrooted.sh
    arch-chroot /mnt \
        env DISK="${DISK}" TIMEZONE="${TIMEZONE}" HOSTNAME="${HOSTNAME}" \
        ESP="${ESP}" ROOT="${ROOT}" \
        bash root/chrooted.sh
    rm /mnt/root/chrooted.sh
}

#Exit if there is no args, 
if (($# == 0 )); then 
    usage
    exit
fi

#TODO:
# --manual|-m 
# --esp|-e
# --root|-r
# --swap|-s
# --with-swap 
# --bootloader|-b   
while [[ $# -gt 0 ]]; do
    case "$1" in 
    -h|--help)
        usage
        exit
        ;;
    -d|--disk)
        if [ "${2:0:1}" == '-' ]; then
            usage
            exit
        fi
        DISK="$2"
        shift 2
        ;;
    -c|--country)
        COUNTRY="$2"
        shift 2
        ;;
    -p|--pkg-list)
        shift
        while [ -n "$1" -a "${1:0:1}" != '-' ]; do
            PKG_LIST+=" $1"
            shift
        done
        ;;
    -t|--timezone)
        TIMEZONE="$2"
        shift 2
        ;;
    -H|--hostname)
        HOSTNAME="$2"
        shift 2
        ;;
    -m|--manual)
        MANUAL="true"
        shift
        ;;
    -r|--root)
        ROOT="$2"
        shift 2
        ;;
    -e|--esp)
        ESP="$2"
        shift 2
        ;;
    esac
done

if [ -n "${MANUAL}" ]; then
    if [ -z "${ESP}" ]; then
        echo "--esp must be specified for --manual"
    elif [ -z "${ROOT}" ]; then
        echo "--root must be specified for --manual"
    fi
fi

if [ -z "${MANUAL}" ]; then
    ESP="${DISK}1"
    ROOT="${DISK}2"
fi

timedatectl set-ntp true

#If not --manual set then new GUID partition table will be created on $DISK
#New partition table will be like:
#/dev/sdX1 /boot ESP  200M
#/dev/sdX2 /     ext4 rest
if [ -z "${MANUAL}" ]; then
    make_part ${DISK} 
fi

#Format ESP to vfat and ROOT to ext4
format_part ${ROOT} ${ESP}

#Mount new parttions to /mnt
mount_part ${ROOT} ${ESP}

#Generate mirrorlist with Russian repo priority
if [ -n "${COUNTRY}" ]; then
    mirrorlist ${COUNTRY}
fi

pacstrap /mnt base ${PKG_LIST}

#Save current mount state
genfstab -U /mnt >> /mnt/etc/fstab

#Run minor install script in chrooted environment
run_chrooted 

#Unmount all parttions from /mnt
umount -R /mnt

#!/bin/bash
#
# Main install script

PWD="${0%/*}"
DISK=/dev/sda
COUNTRY="Russia"
PKG_LIST=""

usage() {
echo "Usage: $0 [-hdcptH]
Options:
    -h|--help                    print this message
    -d|--disk      <Disk>        Specify disk for installation. Default:\"/dev/sda\"
    -c|--country   <Country>     Select country for mirrolist priority. Default: Russia
    -p|--pkg-list  <Package ...> Additional packeges ex:\"base-devel vim iw dialog\" 
    -t|--timezone  <Region/City> Specify timezone Default:\"Europe/Moscow\"
    -H|--hostname  <Hostname>    Hostname Default:\"Arch\"
    "
}
make_part() {
    local disk=${1}
    printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk ${disk}
    yes y | mkfs.vfat ${disk}1
    yes y | mkfs.ext4 ${disk}2
}
mount_part() {
    local disk=${1}
    mount ${disk}2 /mnt
    mkdir /mnt/boot
    mount ${disk}1 /mnt/boot
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
    arch-chroot /mnt env DISK="${DISK}" TIMEZONE="${TIMEZONE}" HOSTNAME="${HOSTNAME}" bash root/chrooted.sh
    rm /mnt/root/chrooted.sh
}

# --help|-h
# --disk|-d
# --conuntr|-c
# --pkg-list|-p
# --timezone|-t
#TODO:
# --esp|-e
# --root|-r
# --with-swap|-s
while [[ $# -gt 0 ]]; do
    case "$1" in 
    -h|--help)
        usage
        exit
        ;;
    -d|--disk)
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
    esac
done

timedatectl set-ntp true

#Make new GUID partition table with on /dev/sda
#New partition table will be like:
#/dev/sdX1 /boot ESP  200M
#/dev/sdX2 /     ext4 rest
make_part ${DISK}

#Mount new parttions to /mnt
mount_part ${DISK}

#Generate mirrorlist with Russian repo priority
mirrorlist ${COUNTRY}

pacstrap /mnt base ${PKG_LIST}

#Save current mount state
genfstab -U /mnt >> /mnt/etc/fstab

#Run minor install script in chrooted environment
run_chrooted 

#Unmount all parttions from /mnt
umount -R /mnt

#!/bin/bash
#
# Main install script

PWD=$(pwd)
DISK=sda
COUNTRY="Russia"
PKG_LIST="base-devel"

make_part() {
    local disk=${1}
    printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk /dev/${disk}
    yes y | mkfs.vfat /dev/${disk}1
    yes y | mkfs.ext4 /dev/${disk}2
}
mount_part() {
    local disk=${1}
    mount /dev/${disk}2 /mnt
    mkdir /mnt/boot
    mount /dev/${disk}1 /mnt/boot
}
mirrorlist() {
    local country=${1}
    cat <(grep ${country} -A1 /etc/pacman.d/mirrorlist) \
        <(grep -v ${country} -A1 /etc/pacman.d/mirrorlist) \
        | sed -e 's/--//g' > .mirrorlist.tmp
    mv .mirrorlist.tmp /etc/pacman.d/mirrorlist
}
run_chrooted() {
    local pwd=${1}
    cp ${pwd}/chrooted.sh /mnt/root/chrooted.sh
    chmod a+x /mnt/root/chrooted.sh
    arch-chroot /mnt bash root/chrooted.sh
    rm /mnt/root/chrooted.sh
}

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
run_chrooted ${PWD}

#Unmount all parttions from /mnt
umount -R /mnt

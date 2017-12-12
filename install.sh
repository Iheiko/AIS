#!/bin/bash

timedatectl set-ntp true

printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk /dev/sda

yes y|mkfs.vfat /dev/sda1
yes y|mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab

cp chrooted.sh /mnt/root/
chmod a+x /mnt/root/chrooted.sh

arch-chroot /mnt bash root/chrooted.sh

umount -R /mnt

#!/bin/bash
#
# Main install script

#save current dirrectory path
PWD=$(pwd)

timedatectl set-ntp true

#Make new GUID partition table with on /dev/sda
#New partition table will be like:
#/dev/sda1 /boot ESP  200M
#/dev/sda2 /     ext4 rest
printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk /dev/sda
yes y | mkfs.vfat /dev/sda1
yes y | mkfs.ext4 /dev/sda2

#Mount new parttions to /mnt
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

#Generate mirrorlist with Russian repo priority
cat <(grep 'Russia' -A1 /etc/pacman.d/mirrorlist) \
    <(grep -v 'Russia' -A1 /etc/pacman.d/mirrorlist) \
    | sed -e 's/--//g' > .mirrorlist.tmp
mv .mirrorlist.tmp /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel

#Save current mount state
genfstab -U /mnt >> /mnt/etc/fstab

#Run minor install script in chrooted environment
cp $PWD/chrooted.sh /mnt/root/chrooted.sh
chmod a+x /mnt/root/chrooted.sh
arch-chroot /mnt bash root/chrooted.sh
rm /mnt/root/chrooted.sh

#Unmount all parttions from /mnt
umount -R /mnt

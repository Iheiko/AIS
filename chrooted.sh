#!/bin/bash

ln -sf /usr/share/zoneinfo/Europ/Moscow /etc/localtime

hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "ArchVB" >> /etc/hostname

echo -e "127.0.0.1	localhost.localdomain	localhost\n\
::1		localhost.localdomain	localhost\n\
127.0.1.1	ArchVB.localdomain	ArchVB" >> /etc/hosts

bootctl --path=/boot install

cp /usr/shar/systemd/bootctl/* /boot/loader/
cd /boot/loader/
mv arch.conf entries
cd entries

PARTUUID=$(blkid | grep sda2 | grep -Po 'PARTUUID=.+$' | grep -Po "\".+\"" | sed -e "s/\"//g") 
echo "PARTUUID=$PARTUUID"
sed -e 's/PARTUUID=XXXX/PARTUUID='$PARTUUID'/;s/rootfstype=XXXX/rootfstype=ext4/' arch.conf

echo DONE!!

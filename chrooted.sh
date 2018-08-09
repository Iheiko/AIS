#!/bin/bash
#
#Minor install script for chrooted environment

if [ -z "${TIMEZONE}" ]; then
    TIMEZONE="Europe/Moscow"
fi

set_time() {
	local timezone=${1}
	ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
	hwclock --systohc
}
set_locale() {
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" >> /etc/locale.conf
}
set_hostname() {
	local hname=${1}
	echo ${hname} >> /etc/hostname 
	echo -e "127.0.0.1	localhost.localdomain	localhost\n\
	::1		localhost.localdomain	localhost\n\
	127.0.1.1	${hname}.localdomain	${hname}" >> /etc/hosts
}
setup_systemd_boot() {
	local disk=${1}
	bootctl --path=/boot install
	cp /usr/share/systemd/bootctl/* /boot/loader/
	cd /boot/loader/
	mv arch.conf entries
	cd entries
	PARTUUID=$(blkid -o value -s PARTUUID /dev/${disk}2)
	echo "PARTUUID=$PARTUUID"
	sed -i -e 's/PARTUUID=XXXX/PARTUUID='$PARTUUID\
	'/;s/rootfstype=XXXX/rootfstype=ext4/' arch.conf
}

#Time configuration
#Set timezone to Moscow and set the Hardware Clock from the System Clock
set_time ${TIMEZONE}

#Locale configuration. Set default locale to en_US.UTF-8.
set_locale

#Hostname configuration
set_hostname ArchVB

#Install and configure systemd-boot
setup_systemd_boot sda

passwd 
systemctl enable dhcpcd
echo DONE!!

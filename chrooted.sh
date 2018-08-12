#!/bin/bash
#
#Minor install script for chrooted environment

if [ -z "${TIMEZONE}" ]; then
    TIMEZONE="UTC"
fi
if [ -z "${HOSTNAME}" ]; then
    HOSTNAME="Arch"
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
    echo -e "127.0.0.1  localhost.localdomain   localhost\n\
::1     localhost.localdomain   localhost\n\
127.0.1.1   ${hname}.localdomain    ${hname}" >> /etc/hosts
}
setup_grub(){
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
}
setup_systemd-boot() {
    local root=${1}
    bootctl --path=/boot install
    cp /usr/share/systemd/bootctl/* /boot/loader/
    cd /boot/loader/
    mv arch.conf entries
    cd entries
    PARTUUID=$(blkid -o value -s PARTUUID "${root}")
    echo "PARTUUID=$PARTUUID"
    sed -i -e 's/PARTUUID=XXXX/PARTUUID='$PARTUUID'/;s/rootfstype=XXXX/rootfstype=ext4/' arch.conf
}

#Time configuration
#Set timezone to Moscow and set the Hardware Clock from the System Clock
set_time "${TIMEZONE}"

#Locale configuration. Set default locale to en_US.UTF-8.
set_locale

#Hostname configuration
set_hostname "${HOSTNAME}"

#Install and configure bootloader
if [[ "${BOOTLOADER}" == "systemd-boot" ]]; then
    setup_systemd-boot ${ROOT} 
elif [[ "${BOOTLOADER}" == "grub" ]]; then
    setup_grub
fi
passwd 
systemctl enable dhcpcd
echo DONE!!

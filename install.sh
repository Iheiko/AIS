#!/bin/bash
#
# Main install script

PWD="${0%/*}"
DISK=""
COUNTRY=""
PKG_LIST=""
MANUAL=""
ROOT=""
ESP=""
SWAP=""
SWAP_SIZE=""

usage() { echo "Usage: $0 (-d <Disk> | -m -r <Partition> -e <Partition>) [-hcptHre]
Required:
    -d|--disk      <Disk>        Specify disk for automated partion creation installation. 
    -m|--manual                  For manual partition selection. --disk will be ignored.
    -r|--root      <Partition>   Root partition(/). Only needed if --manual
    -e|--esp       <Partition>   EFI system partiton. Only needed if --manual
    
Options:
    -h|--help                    print this message
    -c|--country   <Country>     Country for mirrorlist priority. Default: None
    -p|--pkg-list  <Package ...> Additional packages to install
    -t|--timezone  <Region/City> Specify timezone Default:\"UTC\"
    -H|--hostname  <Hostname>    Hostname for installed system Default:\"Arch\"
    --with-swap    <Size>        Swap of <Size> will be created. Works only with --disk.
    -s|--swap      <Partition>   Use partition as swap. Works only with --manual
    "
    exit
}
check_arg_empty() { 
    if [ "$#" == "1" -o "${2:0:1}" == "-" ]; then
        echo "Error: ${1} cant be empty" >&2
        exit
    fi
}
check_size(){
    local size="${1}"
    local check=$(echo "${size}" | grep -Po "\d+[KMGTP]")
    if [ "${size}" != "${check}" ]; then
        echo "Error: Wrong size ${size}, must be: size{K,M,G,T,P}" >&2
        exit 
    fi  
}
format_part() {
    local root=${1}
    local esp=${2}
    yes y | mkfs.vfat $esp
    yes y | mkfs.ext4 $root
}

make_part() {
    local disk=${1}
    local swap_size=${2}
    if [ -z "${swap_size}" ]; then
        printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk ${disk}
    else
        printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n+${swap_size}\nt\n2\n19\nn\n\n\n\nw\n" | fdisk ${disk}
    fi
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
    if [ ! -f "${PWD}/chrooted.sh" ]; then
        minor_location='/usr/share/install/chrooted.sh'
    else
	minor_location="${PWD}/chrooted.sh"
    fi
    cp "${minor_location}" /mnt/root/chrooted.sh
    chmod a+x /mnt/root/chrooted.sh
    arch-chroot /mnt \
        env DISK="${DISK}" TIMEZONE="${TIMEZONE}" HOSTNAME="${HOSTNAME}" \
        ESP="${ESP}" ROOT="${ROOT}" \
        bash root/chrooted.sh
    rm /mnt/root/chrooted.sh
}

#Exit if there is no args, 
if (($# == 0)); then 
    usage
fi

#TODO:
# --bootloader|-b   
# --lvm
# --LUKS/--dm-crypt
while [[ $# -gt 0 ]]; do
    case "$1" in 
    -h|--help)
        usage
        ;;
    -d|--disk)
        check_arg_empty $@
        DISK="$2"
        shift 2
        ;;
    -c|--country)
        check_arg_empty $@
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
        check_arg_empty $@
        TIMEZONE="$2"
        shift 2
        ;;
    -H|--hostname)
        check_arg_empty $@
        HOSTNAME="$2"
        shift 2
        ;;
    -m|--manual)
        MANUAL="true"
        shift
        ;;
    -r|--root)
        check_arg_empty $@
        ROOT="$2"
        shift 2
        ;;
    -e|--esp)
        check_arg_empty $@
        ESP="$2"
        shift 2
        ;;
    -s|--swap)
        check_arg_empty $@
        SWAP="$2"
        shift 2
        ;;
    --with-swap)
        check_arg_empty $@
        check_size "$2"
        SWAP_SIZE="$2"
        shift 2
        ;;
    *)
        echo "Erorr: unknown argument $1"
        exit
        ;;
    esac
done

if [ -z "${MANUAL}" -a -z "${DISK}" ]; then
    echo "Error: At least --disk or --manual must be specified. For more info see --help" >&2 
    exit
fi

#If --manual, then check --root and --esp was specified for --manual
if [ -n "${MANUAL}" ]; then
    if [ -z "${ESP}" ]; then
        echo "--esp must be specified for --manual"
        exit
    elif [ -z "${ROOT}" ]; then
        echo "--root must be specified for --manual"
        exit
    fi
#If not manual, then check for --with-swap was specified and select partition numbers accordingly.
else
    ESP="${DISK}1"
    if [ -z "${SWAP_SIZE}" ]; then
        ROOT="${DISK}2"
    else
        SWAP="${DISK}2"
        ROOT="${DISK}3"
    fi
fi

timedatectl set-ntp true

#If not --manual then new GUID partition table will be created on $DISK
#New partition table will be like:
#$ESP /boot ESP  200M
#$SWAP?          $SWAP_SIZE
#$ROOT /    ext4 rest
if [ -z "${MANUAL}" ]; then
    make_part ${DISK} ${SWAP_SIZE} 
fi

if [ -n "${SWAP}" ]; then
    mkswap "${SWAP}"
    swapon "${SWAP}"
fi

format_part ${ROOT} ${ESP}

mount_part ${ROOT} ${ESP}

#Generate mirrorlist with $COUNTRY repo priority if provided
if [ -n "${COUNTRY}" ]; then
    mirrorlist ${COUNTRY}
fi

pacstrap /mnt base ${PKG_LIST}

genfstab -U /mnt >> /mnt/etc/fstab

#Run minor install script in chrooted environment
run_chrooted 

umount -R /mnt

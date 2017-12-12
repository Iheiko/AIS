#!/bin/bash

timedatectl set-ntp true

printf "g\nn\n\n\n+200M\nt\n1\nn\n\n\n\nw\n" | fdisk /dev/sda

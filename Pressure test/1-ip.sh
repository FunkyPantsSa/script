#! /bin/bash
# CentOS 7/8，Ubuntu 18.04及以上系统拷机脚本
# 12-09-2021

./IPMICFG-Linux.x86_64 -dhcp off
./IPMICFG-Linux.x86_64 -m 192.168.120.120
./IPMICFG-Linux.x86_64 -k 255.255.255.0
./IPMICFG-Linux.x86_64 -user setpwd 2 Abc123456
./IPMICFG-Linux.x86_64 -fan 1

dpkg -i storcli_007.1804.0000.0000_all.deb

apt install gcc g++ make cmake automake vim htop -y

echo -e "blacklist nouveau\noptions nouveau modeset=0" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u
init 3
apt install lightdm -y
init 5
sleep 10s
reboot

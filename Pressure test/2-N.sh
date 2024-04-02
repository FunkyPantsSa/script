#! /bin/bash
# CentOS 7/8，Ubuntu 18.04及以上系统拷机脚本
# 12-09-2021

init 3
./NVIDIA-Linux-x86_64-535.161.07.run --no-opengl-files
/opt/MegaRAID/storcli/storcli64 /c0 show
nvidia-smi
lsmem
lsblk
init 5

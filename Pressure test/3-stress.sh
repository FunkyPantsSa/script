#! /bin/bash
# CentOS 7/8，Ubuntu 18.04及以上系统拷机脚本
# 12-09-2021

#确定系统版本
distr=`cat /proc/version | egrep -oe ubuntu -oe centos`

if [ "$distr" = "ubuntu" ];then
	export ubuntu_ver=`cat /etc/issue|awk '{print $2}'|sed /^$/d`
elif [ "$distr" = "centos" ];then
	export centos_ver=`cat /proc/version|awk '{print $3}'|awk -F. '{print $(NF-1)}'|awk -F_ '{print $(NF-1)}'`
else 
	echo "Incompatible distribution or version."
fi

#CentOS安装epel扩展包
if  [ "$distr" = "centos" -a "$centos_ver" = "el7" ];then
	yum -y install dnf epel-release
elif [ "$distr" = "centos" -a "$centos_ver" = "el8" ];then
	dnf -y install epel-release
else 
	echo "epel-release is NOT needed"
fi

#确认stress-ng是否安装
if  [ "$distr" = "centos" ];then
	export stress=`rpm -qa|grep stress-ng|awk '{print $1}'`
	[ -z "$stress" ] && dnf -y install stress-ng
elif [ "$distr" = "ubuntu" ];then
	export stress=`sudo dpkg --list|grep stress-ng|awk '{print $2}'`
	[ -z "$stress" ] && sudo apt -y install stress-ng
else
	echo "Incompatible distribution or version."
fi

#定义拷机参数
cores=`lscpu|grep CPU\(s\)|sed '2,4d'|awk '{print $(NF)}'`
vms=`expr $cores/2|bc`

#Input Testing Times(minutes or hours)
echo -e "Please input running time，e.g.：30m,1h ect..."
read -p "Test Time：" times

#拷机
if [ "$distr" = "centos" ];then
	stress-ng --cpu $cores --cpu-method prime --vm $vms --vm-bytes=100% -t $times
elif [ "$distr" = "ubuntu" ];then
	sudo stress-ng --cpu $cores --cpu-method prime --vm $vms --vm-bytes=100% -t $times
else
	exit 0
fi
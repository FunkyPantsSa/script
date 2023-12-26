#!/bin/bash
#********************************************************************
#Date:              2023-11-14
#FileName:          install_kubernetes.sh
#Description:       install kubernetes shell script
#Copyright (C):     2023 All rights reserved
#********************************************************************

KUBE_VERSION="1.23.16"
#KUBE_VERSION="1.24.4"
#KUBE_VERSION="1.24.3"
#KUBE_VERSION="1.24.0"
#KUBE_VERSION="1.22.1"
#KUBE_VERSION="1.17.2"
KUBE_VERSION2=$(echo $KUBE_VERSION |awk -F. '{print $2}')

KUBEAPI_IP=10.196.10.118
MASTER1_IP=10.196.10.118
NODE1_IP=10.196.10.119
NODE2_IP=10.196.10.120
GNODE1_IP=10.196.10.125
GNODE2_IP=10.196.10.126
GNODE3_IP=10.196.10.127
GNODE4_IP=10.196.10.128
GNODE5_IP=10.196.10.129
GNODE6_IP=10.196.10.130
GNODE7_IP=10.196.10.131
GNODE8_IP=10.196.10.132
GNODE9_IP=10.196.10.133
GNODE10_IP=10.196.10.134
HARBOR_IP=10.196.10.120

DOMAIN=xffuture.com

MASTER1=master10118.$DOMAIN
NODE1=node10119.$DOMAIN
NODE2=node10120.$DOMAIN
GNODE1=gnode10125.$DOMAIN
GNODE2=gnode10126.$DOMAIN
GNODE3=gnode10127.$DOMAIN
GNODE4=gnode10128.$DOMAIN
GNODE5=gnode10129.$DOMAIN
GNODE6=gnode10130.$DOMAIN
GNODE7=gnode10131.$DOMAIN
GNODE8=gnode10132.$DOMAIN
GNODE9=gnode10133.$DOMAIN
GNODE10=gnode10134.$DOMAIN
HARBOR=harbor.$DOMAIN

POD_NETWORK="10.244.0.0/16"
SERVICE_NETWORK="10.96.0.0/12"

IMAGES_URL="registry.aliyuncs.com/google_containers"

CIR_DOCKER_VERSION=0.2.5
CIR_DOCKER_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CIR_DOCKER_VERSION}/cri-dockerd_${CIR_DOCKER_VERSION}.3-0.ubuntu-${UBUNTU_CODENAME}_amd64.deb"

LOCAL_IP=`hostname -I|awk '{print $1}'`

. /etc/os-release

COLOR_SUCCESS="echo -e \\033[1;32m"
COLOR_FAILURE="echo -e \\033[1;31m"
END="\033[m"


color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "
    elif [ $2 = "failure" -o $2 = "1"  ] ;then
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo
}

check () {
    if [ $ID = 'ubuntu' -a ${VERSION_ID} = "20.04"  ];then
        true
    else
        color "不支持此操作系统，退出!" 1
        exit
    fi
}

install_prepare () {
    cat >> /etc/hosts <<EOF

$KUBEAPI_IP kubeapi.$DOMAIN
$MASTER1_IP $MASTER1
$NODE1_IP $NODE1
$NODE2_IP $NODE2
$GNODE1_IP $GNODE1
$GNODE2_IP $GNODE2
$GNODE3_IP $GNODE3
$GNODE4_IP $GNODE4
$GNODE5_IP $GNODE5
$GNODE6_IP $GNODE6
$GNODE7_IP $GNODE7
$GNODE8_IP $GNODE8
$GNODE9_IP $GNODE9
$GNODE10_IP $GNODE10
$HARBOR_IP $HARBOR
EOF
    hostnamectl set-hostname $(awk -v ip=$LOCAL_IP '{if($1==ip && $2 !~ "kubeapi")print $2}' /etc/hosts)
    swapoff -a
    sed -i '/swap/s/^/#/' /etc/fstab
    color "安装前准备完成!" 0
    sleep 1
}

install_docker () {
    apt update
    apt -y install docker-ce=5:20.10.24~3-0~ubuntu-focal docker-ce-cli=5:20.10.24~3-0~ubuntu-focal || { color "安装Docker失败!" 1; exit 1; }
    cat > /etc/docker/daemon.json <<EOF
{
"registry-mirrors": [
"https://docker.mirrors.ustc.edu.cn",
"https://hub-mirror.c.163.com",
"https://reg-mirror.qiniu.com",
"https://registry.docker-cn.com"
],
 "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
    systemctl restart docker.service
    docker info && { color "安装Docker成功!" 0; sleep 1; } || { color "安装Docker失败!" 1 ; exit 2; }
}

install_kubeadm () {
    apt-get update && apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
    apt-get update
    apt-cache madison kubeadm |head
    ${COLOR_FAILURE}"5秒后即将安装: kubeadm-"${KUBE_VERSION}" 版本....."${END}
    ${COLOR_FAILURE}"如果想安装其它版本，请按ctrl+c键退出，修改版本再执行"${END}
    sleep 6

    #安装指定版本
    apt install -y  kubeadm=${KUBE_VERSION}-00 kubelet=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
    [ $? -eq 0 ] && { color "安装kubeadm成功!" 0;sleep 1; } || { color "安装kubeadm失败!" 1 ; exit 2; }

    #实现kubectl命令自动补全功能
    kubectl completion bash > /etc/profile.d/kubectl_completion.sh
}

#Kubernetes-v1.24之前版本无需安装cri-dockerd
install_cri_dockerd () {
    [ $KUBE_VERSION2 -lt 24 ] && return
    if [ ! -e cri-dockerd_${CIR_DOCKER_VERSION}.3-0.ubuntu-${UBUNTU_CODENAME}_amd64.deb ];then
        curl -LO $CIR_DOCKER_URL || { color "下载cri-dockerd失败!" 1 ; exit 2; }
    fi
    dpkg -i cri-dockerd_${CIR_DOCKER_VERSION}.3-0.ubuntu-${UBUNTU_CODENAME}_amd64.deb
    [ $? -eq 0 ] && color "安装cri-dockerd成功!" 0 || { color "安装cri-dockerd失败!" 1 ; exit 2; }
    sed -i '/^ExecStart/s#$# --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:3.7#'   /lib/systemd/system/cri-docker.service
    systemctl daemon-reload
    systemctl restart cri-docker.service
    [ $? -eq 0 ] && { color "配置cri-dockerd成功!" 0 ; sleep 1; } || { color "配置cri-dockerd失败!" 1 ; exit 2; }
}

#只有Kubernetes集群的第一个master节点需要执行下面初始化函数
kubernetes_init () {
    if [ $KUBE_VERSION2 -lt 24 ] ;then
        kubeadm init --control-plane-endpoint="kubeapi.$DOMAIN" \
                 --kubernetes-version=v${KUBE_VERSION}  \
                 --pod-network-cidr=${POD_NETWORK} \
                 --service-cidr=${SERVICE_NETWORK} \
                 --token-ttl=0  \
                 --upload-certs \
                 --image-repository=${IMAGES_URL}
    else
    #Kubernetes-v1.24版本前无需加选项 --cri-socket=unix:///run/cri-dockerd.sock
        kubeadm init --control-plane-endpoint="kubeapi.$DOMAIN" \
                 --kubernetes-version=v${KUBE_VERSION}  \
                 --pod-network-cidr=${POD_NETWORK} \
                 --service-cidr=${SERVICE_NETWORK} \
                 --token-ttl=0  \
                 --upload-certs \
                 --image-repository=${IMAGES_URL} \
                 --cri-socket=unix:///run/cri-dockerd.sock
    fi
    [ $? -eq 0 ] && color "Kubernetes集群初始化成功!" 0 || { color "Kubernetes集群初始化失败!" 1 ; exit 3; }
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
}

reset_kubernetes() {
    kubeadm reset -f --cri-socket unix:///run/cri-dockerd.sock
    rm -rf  /etc/cni/net.d/  $HOME/.kube/config
}


check

PS3="请选择编号(1-4): "
ACTIONS="
初始化新的Kubernetes集群
加入已有的Kubernetes集群
退出Kubernetes集群
退出本程序
"
select action in $ACTIONS;do
    case $REPLY in
    1)
        install_prepare
        install_docker
        install_kubeadm
        install_cri_dockerd
        kubernetes_init
        break
        ;;
    2)
        install_prepare
        install_docker
        install_kubeadm
        install_cri_dockerd
        $COLOR_SUCCESS"加入已有的Kubernetes集群已准备完毕,还需要执行最后一步加入集群的命令 kubeadm join !"${END}
        break
        ;;
    3)
        reset_kubernetes
        break
        ;;
    4)
        exit
        ;;
    esac
done
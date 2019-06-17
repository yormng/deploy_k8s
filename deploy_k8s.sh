#!/bin/bash

#/*
#  MAINTAINER yormng
#  VERSION 1.0	*/

#KUBERNETES VERSION 1.11.2
#KUBEADM VERSION 1.11.2
#KUBELET VERSION 1.11.2
#KUBECTL VERSION 1.11.2

NODE1_IP=192.168.114.12
NODE2_IP=192.168.114.13
NODE1=root@192.168.114.12
NODE2=root@192.168.114.13

ssh-keygen -t rsa
ssh-copy-id $NODE2

hostnamectl set-hostname k8s-master
ssh $NODE2 hostnamectl set-hostname k8s-node1

systemctl stop firewalld && systemctl disable firewalld
ssh $NODE2 systemctl stop firewalld && systemctl disable firewalld

sed -i 's/SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
ssh $NODE2 sed -i 's/SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
setenforce 0
ssh $NODE2 setenforce 0

yum -y install yum-utils device-mapper-persistent-data lvm2
ssh $NODE2 yum -y install yum-utils device-mapper-persistent-data lvm2

yum -y localinstall https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.3.ce-1.el7.noarch.rpm
ssh $NODE2 yum -y localinstall https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.3.ce-1.el7.noarch.rpm

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
ssh $NODE2  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum -y install docker-ce-17.03.3.ce
ssh $NODE2 yum -y install docker-ce-17.03.3.ce

systemctl start docker && systemctl enable docker
ssh $NODE2 "systemctl start docker && systemctl enable docker"

cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
ssh $NODE2 "
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
"
yum -y install kubectl-1.11.2
ssh $NODE2 yum -y install kubectl-1.11.2
yum -y install kubelet-1.11.2
ssh $NODE2 yum -y install kubelet-1.11.2
yum -y install kubeadm-1.11.2
ssh $NODE2 yum -y install kubeadm-1.11.2
systemctl enable kubelet && systemctl start kubelet
ssh $NODE2 "systemctl enable kubelet && systemctl start kubelet"

## Define some environment args for pulling images. ##
K8S_VERSION=v1.11.2
ETCD_VERSION=3.2.18
DASHBOARD_VERSION=v1.8.3
FLANNEL_VERSION=v0.10.0-amd64
DNS_VERSION=1.1.3
PAUSE_VERSION=3.1

## Pull the images k8s needs by using aliyun package source. ##
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:$K8S_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:$ETCD_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:$PAUSE_VERSION
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:$DNS_VERSION

## Load the image for k8s network. ##
docker load -i flannel_k8s.tar

## Tag this images by using a specific prefix. ##
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:$K8S_VERSION k8s.gcr.io/kube-apiserver-amd64:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:$K8S_VERSION k8s.gcr.io/kube-controller-manager-amd64:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:$K8S_VERSION k8s.gcr.io/kube-scheduler-amd64:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:$K8S_VERSION k8s.gcr.io/kube-proxy-amd64:$K8S_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:$ETCD_VERSION k8s.gcr.io/etcd-amd64:$ETCD_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:$PAUSE_VERSION k8s.gcr.io/pause:$PAUSE_VERSION
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:$DNS_VERSION k8s.gcr.io/coredns:$DNS_VERSION

## Delete the redundant images. ##
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:$K8S_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:$K8S_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:$K8S_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:$K8S_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:$ETCD_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/pause:$PAUSE_VERSION
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:$DNS_VERSION
scp ./flannel_k8s.tar $NODE2:/root/

ssh $NODE2 "

## Pull the images k8s needs by using aliyun package source. ##
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:v1.11.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:v1.11.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:v1.11.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:v1.11.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:3.2.18
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.1.3

## Load the image for k8s network. ##
docker load -i flannel_k8s.tar

## Tag this images by using a specific prefix. ##
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:v1.11.2 k8s.gcr.io/kube-apiserver-amd64:v1.11.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:v1.11.2 k8s.gcr.io/kube-controller-manager-amd64:v1.11.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:v1.11.2 k8s.gcr.io/kube-scheduler-amd64:v1.11.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:v1.11.2 k8s.gcr.io/kube-proxy-amd64:v1.11.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:3.2.18 k8s.gcr.io/etcd-amd64:3.2.18
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.1.3 k8s.gcr.io/coredns:1.1.3

## Delete the redundant images. ##
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver-amd64:v1.11.2
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager-amd64:v1.11.2
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler-amd64:v1.11.2
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:v1.11.2
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/etcd-amd64:3.2.18
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.1.3
"

swapoff -a
ssh $NODE2 swapoff -a

kubeadm init --kubernetes-version=1.11.2 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$NODE1_IP | tee ./kubeadm.log

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
grep "kubeadm join" ./kubeadm.log | xargs ssh $NODE2
rm -f ./kubeadm.log

kubectl apply -f ./kube-flannel.yml

kubectl apply -f ./kubernetes-dashboard.yaml

kubectl create -f ./k8s-admin.yaml

echo -e "\033[32m \033[1m";kubectl describe secret $(kubectl get secret -n kube-system | grep dashboard-admin | awk '{print $1}') -n kube-system | grep -w "token:" | awk '{print $2}'
echo -e "\033[0m"
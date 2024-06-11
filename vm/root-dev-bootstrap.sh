#!/bin/bash

# Print commands and exit on errors
set -xe

export DEBIAN_FRONTEND=noninteractive

apt-get update -q

apt-get install -qq -y --no-install-recommends --fix-missing \
  ca-certificates curl jq git net-tools python3 python3-pip tcpdump unzip \
  vim wget make gcc libc6-dev flex bison libelf-dev libssl-dev dpkg-dev build-essential debhelper \
  pkg-config cmake autoconf automake libtool g++ libboost-dev libboost-iostreams-dev libboost-graph-dev \
  libfl-dev libgc-dev llvm clang gcc-multilib dwarves libmnl-dev \
  docker.io bridge-utils wireshark desktop-file-utils \
  xfce4 xfce4-goodies tightvncserver chromium-browser meld tree terminator
sudo snap install --classic code
  # rdma-core rdmacm-utils
# sudo gpasswd -a $USER wireshark
wget https://github.com/siemens/cshargextcap/releases/download/v0.10.7/cshargextcap_0.10.7_linux_amd64.deb
sudo dpkg -i cshargextcap_0.10.7_linux_amd64.deb
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# sudo service docker restart
echo "deb [trusted=yes] https://apt.fury.io/netdevops/ /" | sudo tee -a /etc/apt/sources.list.d/netdevops.list
sudo apt update && sudo apt install containerlab

# NOTE: optionally Leave out of image to speedup vagrant builds; docker pull will happen upon first invocation of docker run
# sudo docker pull p4lang/p4c
sudo usermod -aG docker vagrant

# Compile and install kernel with P4TC support
git clone https://github.com/p4tc-dev/linux-p4tc-pub.git
cd linux-p4tc-pub/
cp ./config-guest-p4tc-x86 .config
\/home/vagrant/linux-p4tc-pub/scripts/kconfig/merge_config.sh .config \/home/vagrant/linux-p4tc-pub/tools/testing/selftests/tc-testing/config
make olddefconfig
make -j`nproc`
make modules_install && make install

# Download and compile libbpf
mkdir -p /home/vagrant/libs
cd /home/vagrant/libs
git clone https:\//github.com/libbpf/libbpf.git
cd libbpf/src
mkdir build root
BUILD_STATIC_ONLY=y OBJDIR=build DESTDIR=root make install

# Download and compile iproute2
cd /home/vagrant/libs/
git clone https:\//github.com/p4tc-dev/iproute2-p4tc-pub
cd iproute2-p4tc-pub/
\/home/vagrant/libs/iproute2-p4tc-pub/configure --libbpf_dir \/home/vagrant/libs/libbpf/src/root/
make && make install && cp etc/iproute2/p4tc_entities /etc/iproute2 && cp -r etc/iproute2/p4tc_entities.d /etc/iproute2

# Download and compile protobuf (required by p4c)
cd /home/vagrant/libs/
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.18.1
git submodule update --init --recursive
./autogen.sh
./configure
make -j`nproc`
make install && ldconfig

sudo pip3 install scapy

# Download and compile p4c
cd /home/vagrant/libs/
#git clone --recursive https://github.com/p4lang/p4c.git
git clone --recursive https://github.com/komaljai/p4c.git
cd p4c
git checkout fix_extern_template
git submodule update --init --recursive
mkdir -p build
cd build
cmake .. -DENABLE_P4TC=ON -DENABLE_DPDK=OFF
make -j`nproc`
make install

#get examples
cd /home/vagrant
git clone https://github.com/p4tc-dev/p4tc-examples-pub.git

#get sendpacket
cd /home/vagrant
git clone https://github.com/ebiken/sendpacket

#running depmod
sudo depmod -a
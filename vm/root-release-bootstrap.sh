#!/bin/bash

# Print commands and exit on errors
set -xe

export DEBIAN_FRONTEND=noninteractive

apt-get update -q

apt-get install -qq -y --no-install-recommends --fix-missing \
  ca-certificates curl git net-tools python3 python3-pip tcpdump unzip \
  vim wget make gcc libc6-dev flex bison libelf-dev libssl-dev dpkg-dev build-essential debhelper \
  pkg-config cmake autoconf automake libtool g++ libboost-dev libboost-iostreams-dev libboost-graph-dev \
  libfl-dev libgc-dev llvm clang

# Compile and install kernel with P4TC support
git clone https://github.com/p4tc-dev/linux-p4tc-pub.git
cd linux-p4tc-pub/
cp /home/vagrant/config-p4tc-x86-ubuntu-22.04 .config
make olddefconfig
make -j`nproc`
make modules_install && make install

# Download and compile libbpf
mkdir libs
cd libs
git clone https:\//github.com/libbpf/libbpf.git
cd libbpf/src
mkdir build root
BUILD_STATIC_ONLY=y OBJDIR=build DESTDIR=root make install

# Download and compile iproute2
cd /home/vagrant/libs/
git clone https:\//github.com/p4tc-dev/iproute2-p4tc-pub
cd iproute2-p4tc-pub/
\/home/vagrant/libs/iproute2-p4tc-pub/configure --libbpf_dir \/home/vagrant/libs/libbpf/src/root/
make && make install

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

# Download and compile p4c
cd /home/vagrant/libs/
git clone --recursive https://github.com/p4lang/p4c.git
cd p4c
git submodule update --init --recursive
mkdir build
cd build
cmake .. -DENABLE_P4TC=ON -DENABLE_DPDK=OFF
make -j`nproc`
make install

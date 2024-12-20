#!/bin/bash

set -e

chroot_dir="chroot /home/"$SUDO_USER"/chroot-amd64"

function sources_list {
  cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
EOF

  apt update
}

function add_chroot {

  apt install debootstrap qemu-user-static -y
  debootstrap --arch=amd64 --components=main,contrib,non-free 1.7_x86-64 chroot-amd64 http://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/

  $chroot_dir bash -c "cat << EOF > /etc/apt/sources.list
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
EOF"

  $chroot_dir bash -c "echo \"export LC_ALL=C\" >> /root/.bashrc"
  $chroot_dir apt update
  $chroot_dir apt install devscripts quilt equivs unzip wget build-essential -y
}


function install_iperf3 {
  version="3.18-1"
  chroot_iperf="/opt/iperf-3.18"

  $chroot_dir wget -P /opt https://github.com/esnet/iperf/releases/download/3.18/iperf-3.18.tar.gz
  $chroot_dir tar -xzvf /opt/iperf-3.18.tar.gz -C /opt
  $chroot_dir mkdir /opt/iperf-3.18/debian

  $chroot_dir bash -c "cat << EOF > /opt/iperf-3.18/debian/control
Source: iperf3
Section: net
Priority: optional
Maintainer: AnilAntari
Build-Depends: debhelper (>=9), build-essential

Package: iperf3
Version: $version
Architecture: amd64
Depends: debconf, adduser, libc6, debconf (>= 0.5) | debconf-2.0
Homepage: https://github.com/esnet/iperf
Description: Internet Protocol bandwidth measuring tool
 Iperf3 is a tool for performing network throughput measurements. It can
 test either TCP or UDP throughput.
 .
 This is a new implementation that shares no code with the original
 iperf from NLANR/DAST and also is not backwards compatible.
 .
EOF"

  $chroot_dir bash -c "echo \"9\" > /opt/iperf-3.18/debian/compat"

  $chroot_dir bash -c "cat << EOF > /opt/iperf-3.18/debian/changelog
iperf3 ($version) stretch; urgency=medium

  * Creating a package with version 3.18.

  -- AnilAntari   $(date -R)
EOF"

  $chroot_dir bash -c "printf \"#!/usr/bin/make -f\n\n\" > /opt/iperf-3.18/debian/rules"
  $chroot_dir bash -c "printf \"clean:\n\t@# Do nothing\n\n\" >> /opt/iperf-3.18/debian/rules"
  $chroot_dir bash -c "printf \"build:\n\tmkdir -p debian/iperf3/usr\n\t./configure --prefix=/opt/iperf-3.18/debian/iperf3/usr\n\tmake\n\tmake check\n\tmake install\n\n\" >> /opt/iperf-3.18/debian/rules"
  $chroot_dir bash -c "printf \"binary:\n\tmkdir -p debian/iperf3/usr/share/doc/iperf3\n\tmkdir -p debian/iperf3/usr/share/lib/systemd/system\n\tcp README.md debian/iperf3/usr/share/doc/iperf3\n\tchmod 0644 debian/iperf3/usr/share/doc/iperf3/README.md\n\tcp contrib/iperf3.service debian/iperf3/usr/share/lib/systemd/system\n\tchmod 0644 debian/iperf3/usr/share/lib/systemd/system\n\tdh_gencontrol\n\tdh_builddeb\n\" >> /opt/iperf-3.18/debian/rules"

  $chroot_dir << EOF
cd /opt/iperf-3.18
dpkg-buildpackage -b
EOF
}

sources_list
add_chroot
install_iperf3

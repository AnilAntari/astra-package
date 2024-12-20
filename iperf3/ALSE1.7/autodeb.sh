#!/bin/bash

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

  chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cat << EOF > /etc/apt/sources.list
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
EOF"

  echo "export LC_ALL=C" | chroot /home/"$SUDO_USER"/chroot-amd64 tee -a /root/.bashrc
  chroot /home/"$SUDO_USER"/chroot-amd64 apt update
  chroot /home/"$SUDO_USER"/chroot-amd64 apt install devscripts quilt equivs unzip wget -y
}

function install_iperf3 {
	
	dir="iperf3-3.18-1_amd64"
	
	chroot /home/"$SUDO_USER"/chroot-amd64 wget -P /opt https://github.com/esnet/iperf/releases/download/3.18/iperf-3.18.tar.gz
	chroot /home/"$SUDO_USER"/chroot-amd64 tar -xzvf /opt/iperf-3.18.tar.gz -C /opt
	chroot /home/"$SUDO_USER"/chroot-amd64 mkdir /opt/$dir/usr
    chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cd /opt/iperf-3.18/ && ./configure --prefix=/opt/$dir/usr"
	chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cd /opt/iperf-3.18/ && make" 
	chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cd /opt/iperf-3.18/ && make check"
	sleep 10
	chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cd /opt/iperf-3.18/ && make install"
	chroot /home/"$SUDO_USER"/chroot-amd64 mkdir -p /opt/$dir/usr/{lib/systemd/system,share/doc}
	chroot /home/"$SUDO_USER"/chroot-amd64 cp /opt/iperf-3.18/README.md /opt/$dir/usr/share/doc
	chroot /home/"$SUDO_USER"/chroot-amd64 chmod 644 /opt/$dir/usr/share/doc/README.md
	chroot /home/"$SUDO_USER"/chroot-amd64 cp /opt/iperf-3.18/contrib/iperf3.service /opt/$dir/usr/lib/systemd/system
	chroot /home/"$SUDO_USER"/chroot-amd64 chmod 644 /opt/$dir/usr/lib/systemd/system/iperf3.service
	chroot /home/"$SUDO_USER"/chroot-amd64 mkdir /opt/$dir/DEBIAN
	chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cat << EOF > /opt/$dir/DEBIAN/control
Package: iperf3
Version: 3.18-1
Architecture: amd64
Maintainer: AnilAntari
Depends: debconf, adduser, libc6, libiperf0, debconf (>= 0.5) | debconf-2.0
Section: net
Priority: optional
Homepage: https://github.com/esnet/iperf
Description: Internet Protocol bandwidth measuring tool
 Iperf3 is a tool for performing network throughput measurements. It can
 test either TCP or UDP throughput.
 .
 This is a new implementation that shares no code with the original
 iperf from NLANR/DAST and also is not backwards compatible.
 .
 This package contains the command line utility.
EOF"
	chroot /home/"$SUDO_USER"/chroot-amd64 dpkg-deb --build /opt/$dir
	apt install ./chroot-amd64/opt/iperf3-3.18-1_amd64.deb -y
}

sources_list
add_chroot
install_iperf3

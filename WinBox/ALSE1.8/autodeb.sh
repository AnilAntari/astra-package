#!/bin/bash

set -e

chroot_dir="chroot /home/"$SUDO_USER"/chroot-amd64"

function sources_list {
  cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free non-free-firmware
deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/extended-repository/ 1.8_x86-64 main contrib non-free non-free-firmware
EOF

  apt update
}

function add_chroot {

  apt install debootstrap qemu-user-static -y
  debootstrap --arch=amd64 --components=main,contrib,non-free,non-free-firmware 1.8_x86-64 chroot-amd64 https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/

  $chroot_dir bash -c "cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ 1.8_x86-64 main contrib non-free non-free-firmware
deb https://dl.astralinux.ru/astra/stable/1.8_x86-64/extended-repository/ 1.8_x86-64 main contrib non-free non-free-firmware
EOF"

  $chroot_dir bash -c "echo \"export LC_ALL=C\" >> /root/.bashrc"
  $chroot_dir apt update
  $chroot_dir apt install devscripts quilt equivs unzip wget build-essential -y
}

function install_winbox {
  version=16

  $chroot_dir wget -P /opt https://download.mikrotik.com/routeros/winbox/4.0beta"$version"/WinBox_Linux.zip
  $chroot_dir mkdir /opt/winbox4.0beta"$version"
  $chroot_dir mkdir -p /opt/winbox4.0beta"$version"/debian/winbox/usr/{share/pixmaps,share/applications,share/winbox,bin}
  $chroot_dir unzip /opt/WinBox_Linux.zip -d /opt/winbox4.0beta"$version"
  $chroot_dir bash -c "cat << EOF > /opt/winbox4.0beta"$version"/debian/winbox/usr/share/applications/winbox.desktop
[Desktop Entry]
Type=Application
Version=1.0
Name=WinBox
Comment=GUI administration for Mikrotik RouterOS
Exec=/usr/bin/env --unset=QT_QPA_PLATFORM /usr/bin/WinBox
Icon=winbox
Terminal=false
Categories=Utility
StartupWMClass=WinBox
EOF"

  $chroot_dir bash -c "cat << EOF > /opt/winbox4.0beta"$version"/debian/control
Source: winbox
Section: Application/Tools
Priority: optional
Maintainer: AnilAntari
Build-Depends: debhelper (>=9), build-essential

Package: winbox
Version: 4.0beta"$version"-1
Origin: WinBox
Architecture: amd64
Homepage: https://mikrotik.com/download
Description: MikroTik RouterOS GUI Configurator
EOF"

  $chroot_dir bash -c "echo \"9\" > /opt/winbox4.0beta"$version"/debian/compat"

  $chroot_dir bash -c "cat << EOF > /opt/winbox4.0beta"$version"/debian/changelog
winbox (4.0beta$version-1) stretch; urgency=medium

  * Creating a package with version 4.0beta"$version".

  -- AnilAntari   $(date -R)
EOF"

  $chroot_dir bash -c "printf \"#!/usr/bin/make -f\n\n\" > /opt/winbox4.0beta\"$version\"/debian/rules"
  $chroot_dir bash -c "printf \"clean:\n\t@# Do nothing\n\n\" >> /opt/winbox4.0beta\"$version\"/debian/rules"
  $chroot_dir bash -c "printf \"build:\n\t@# Do nothing\n\n\" >> /opt/winbox4.0beta\"$version\"/debian/rules"
  $chroot_dir bash -c "printf \"binary:\n\tmkdir -p debian/winbox/usr/share/pixmaps\n\tcp WinBox debian/winbox/usr/bin\n\tcp assets/img/winbox.png debian/winbox/usr/share/pixmaps\n\tchmod 755 debian/winbox/usr/bin/WinBox\n\tchmod 644 debian/winbox/usr/share/pixmaps/winbox.png\n\tchmod 644 debian/winbox/usr/share/applications/winbox.desktop\n\t\tdh_gencontrol\n\tdh_builddeb\n\" >> /opt/winbox4.0beta\"$version\"/debian/rules"

  $chroot_dir << EOF
cd /opt/winbox4.0beta"$version"
dpkg-buildpackage -b
EOF
}

sources_list
add_chroot
install_winbox

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

function install_winbox {
  version=14

  $chroot_dir wget -P /opt https://download.mikrotik.com/routeros/winbox/4.0beta14/WinBox_Windows.zip
  $chroot_dir mkdir /opt/winbox4.0beta"$version"
  $chroot_dir mkdir -p /opt/winbox4.0beta"$version"/debian/winbox/usr/{share/pixmaps,share/applications,share/winbox,bin}
  $chroot_dir unzip /opt/WinBox_Windows.zip -d /opt/winbox4.0beta"$version"
  $chroot_dir bash -c "cat << EOF > /opt/winbox4.0beta"$version"/debian/winbox/usr/share/applications/winbox.desktop
[Desktop Entry]
Type=Application
Version=1.0
Name=WinBox
Comment=GUI administration for MikroTik RouterOS
Exec=/usr/bin/winbox
Icon=winbox
Terminal=false
Categories=Utility
StartupWMClass=WinBox.exe
EOF"

 $chroot_dir bash -c "echo '#!/bin/bash
export WINEPREFIX=\"\$HOME\"/.winbox/wine
export WINEARCH=win64
export WINEDLLOVERRIDES=\"mscoree=\" # disable mono
export WINEDEBUG=-all
if [ ! -d \"\$HOME\"/.winbox ] ; then
   mkdir -p \"\$HOME\"/.winbox/wine
   wineboot -u
fi

wine /usr/share/winbox/WinBox.exe \"\$@\"' > /opt/winbox4.0beta"$version"/debian/winbox/usr/bin/winbox"

  $chroot_dir bash -c "cat << EOF > /opt/winbox4.0beta"$version"/debian/control
Source: winbox
Section: Application/Tools
Priority: optional
Maintainer: AnilAntari
Build-Depends: debhelper (>=9), build-essential

Package: winbox
Version: 4.0beta"$version"-1
Origin: WinBox
Depends: wine, wine-mono, wine-gecko
Architecture: amd64
Homepage: https://mikrotik.com/download
Description: MikroTik RouterOS GUI Configurator (wine)
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
  $chroot_dir bash -c "printf \"binary:\n\tmkdir -p debian/winbox/usr/share/pixmaps\n\tcp WinBox.exe debian/winbox/usr/share/winbox\n\tcp assets/img/winbox.png debian/winbox/usr/share/pixmaps\n\tchmod 755 debian/winbox/usr/share/winbox/WinBox.exe\n\tchmod 755 debian/winbox/usr/bin/winbox\n\tchmod 644 debian/winbox/usr/share/pixmaps/winbox.png\n\tchmod 644 debian/winbox/usr/share/applications/winbox.desktop\n\t\tdh_gencontrol\n\tdh_builddeb\n\" >> /opt/winbox4.0beta\"$version\"/debian/rules"

  $chroot_dir << EOF
cd /opt/winbox4.0beta"$version"
dpkg-buildpackage -b
EOF
}

sources_list
add_chroot
install_winbox

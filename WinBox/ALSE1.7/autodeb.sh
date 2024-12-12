number=14

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

  debootstrap --arch=amd64 --components=main,contrib,non-free 1.7_x86-64 chroot-amd64 http://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/

  chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cat << EOF > /etc/apt/sources.list
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free
deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
EOF"

  echo "export LC_ALL=C" | chroot /home/"$SUDO_USER"/chroot-amd64 tee -a /root/.bashrc
  chroot /home/"$SUDO_USER"/chroot-amd64 apt update
  chroot /home/"$SUDO_USER"/chroot-amd64 apt install devscripts quilt equivs unzip wget -y
}

function install_winbox {
  chroot /home/"$SUDO_USER"/chroot-amd64 wget -P /opt https://download.mikrotik.com/routeros/winbox/4.0beta14/WinBox_Windows.zip
  chroot /home/"$SUDO_USER"/chroot-amd64 unzip /opt/WinBox_Windows.zip -d /opt/
  chroot /home/"$SUDO_USER"/chroot-amd64 mkdir -p /opt/winbox4.0beta"$number"/usr/{share/pixmaps,share/applications,share/winbox,bin}
  chroot /home/"$SUDO_USER"/chroot-amd64 cp /opt/WinBox.exe /opt/winbox4.0beta"$number"/usr/share/winbox
  chroot /home/"$SUDO_USER"/chroot-amd64 cp /opt/assets/img/winbox.png /opt/winbox4.0beta"$number"/usr/share/pixmaps
  chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cat << EOF > /opt/winbox4.0beta"$number"/usr/share/applications/winbox.desktop
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

  chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "echo '#!/bin/bash
export WINEPREFIX=\"\$HOME\"/.winbox/wine
export WINEARCH=win64
export WINEDLLOVERRIDES=\"mscoree=\" # disable mono
export WINEDEBUG=-all
if [ ! -d \"\$HOME\"/.winbox ] ; then
   mkdir -p \"\$HOME\"/.winbox/wine
   wineboot -u
fi

wine /usr/share/winbox/WinBox.exe \"\$@\"' > /opt/winbox4.0beta"$number"/usr/bin/winbox"

  chroot /home/"$SUDO_USER"/chroot-amd64 mkdir /opt/winbox4.0beta"$number"/DEBIAN
  chroot /home/"$SUDO_USER"/chroot-amd64 bash -c "cat << EOF > /opt/winbox4.0beta"$number"/DEBIAN/control
Package: winbox
Version: 4.0beta"$number"-1
Priority: optional
Origin: WinBox
Section: Application/Tools
Maintainer: AnilAntari
Depends: wine, wine-mono, wine-gecko
Architecture: amd64
Homepage: https://mikrotik.com/download
Description: MikroTik RouterOS GUI Configurator (wine)
EOF"

  chroot /home/"$SUDO_USER"/chroot-amd64 chmod 755 /opt/winbox4.0beta"$number"/usr/share/winbox/WinBox.exe
  chroot /home/"$SUDO_USER"/chroot-amd64 chmod 755 /opt/winbox4.0beta"$number"/usr/bin/winbox
  chroot /home/"$SUDO_USER"/chroot-amd64 chmod 644 /opt/winbox4.0beta"$number"/usr/share/pixmaps/winbox.png
  chroot /home/"$SUDO_USER"/chroot-amd64 chmod 644 /opt/winbox4.0beta"$number"/usr/share/applications/winbox.desktop
  chroot /home/"$SUDO_USER"/chroot-amd64 dpkg-deb --build /opt/winbox4.0beta"$number"
  chroot /home/"$SUDO_USER"/chroot-amd64 mv /opt/winbox4.0beta"$number".deb /opt/winbox_4.0beta"$number"-1_amd64.deb

  apt install /home/"$SUDO_USER"/chroot-amd64/opt/winbox_4.0beta"$number"-1_amd64.deb
}

sources_list
add_chroot
install_winbox

#!/bin/bash
# A script for installing and setting up the base ARCH installation with everything I want, inside a virtual machine
# Notably: Bash utils, zsh + commandline utilities, neovim,  X11 with awesomewm (git version), firefox, kitty, and paru as an AUR helper
#
# Autologin with lightdm, network to automatically work with systemd, grub to auto choose arch.
# No root user password, but sudo setup correctly for my main account.
#
# Steps are:
# - Install base pacman packages (presumably git + base are already there if I'm in this repo)
# - Create user, assign password and to sudo group
# - copy config files and setup systemctl
# - install paru
# - install remaining aur packages
# - install the virtualbox guest additions from ISO
echo "Step 1: Install base pacman packages"
pacman -Sy --needed \
    base base-devel neovim git openssh fuse sudo archlinux-keyring xorg xf86-video-vmware \
    lightdm lightdm-gtk-greeter kitty tmux zsh rustup linux-headers grub unzip xterm \
    dhcpcd docker
echo ""
echo "Step 1 completed"
echo ""
echo "Step 2: Create user, assign password and add to sudo group"
echo "Please provide a username:"
read USER
echo "Creating user $USER"
useradd -m $USER
echo "Please give a password for this user:"
passwd $USER
groupadd sudo
groupadd docker
groupadd autologin
groupadd nopasswdlogin
usermod -aG sudo $USER
usermod -aG docker $USER
usermod -aG autologin $USER
usermod -aG nopasswdlogin $USER
echo ""
echo "Step 2 complete"
echo ""
echo "Step 3: Configuration setup"
echo ""
cp ~/dotfiles/bootstrap/20-wired.network /etc/systemd/network/20-wired.network
cp ~/dotfiles/bootstrap/sudoers /etc/sudoers
chmod 400 /etc/sudoers
cp ~/dotfiles/bootstrap/lightdm.conf /etc/lightdm/lightdm.conf
cp ~/dotfiles/bootstrap/lightdm-pam /etc/pam.d/lightdm
cp ~/dotfiles/bootstrap/grub /etc/default/grub
grub-install /dev/sda
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
cp ~/dotfiles/bootstrap/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf
systemctl enable lightdm
systemctl enable systemd-networkd
systemctl enable docker
echo "BTW: /etc/lightdm/lightdm.conf is only setup for miek as the user. You may need to manually edit this yourself"
echo "press enter to do this/acknowledge"
read varname
echo ""
echo "Step 3 complete"
echo ""
echo "Step 4: install paru"
HOME=/home/$USER sudo -i -u $USER << EOF
rustup default stable
EOF
HOME=/home/$USER sudo -i -u $USER << EOF
git clone https://aur.archlinux.org/paru.git /home/$USER/paru
cd /home/$USER/paru
makepkg -si --noconfirm
EOF
echo ""
echo "Step 5: Install remaining AUR packages"
echo ""
HOME=/home/$USER sudo -i -u $USER << EOF
paru -S --noconfirm --needed\
    awesome-git rofi acpid jq feh pulseaudio inotify-tools xdotool picom \
    xsel firefox kitty
EOF
echo ""
echo "Step 6 complete"
echo ""
echo "Step 7: Install the virtualbox guest additions"
echo "Manual step: Insert the guest additions (press enter when done)"
read varname
mkdir /media/cdrom
mount /dev/sr0 /media/cdrom
/media/cdrom/VBoxLinuxAdditions.run
echo ""
echo "Step 7 complete"
echo ""
echo "Setup and install complete! You probably need to reboot for your changes to take effect"

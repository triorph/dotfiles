# Bootstrap

The purpose of this folder is to provide scripts to automate the setup of a new environment with my various dotfiles

Files are:
## setup_and_install_arch.sh

From a minimal arch installation, end up with everything installed.

Installs:
base:
base base-devel neovim git openssh archlinux-keyring fuse sudo 

package management:
paru rustup

X11:
xorg xf86-video-vmware lightdm lightdm-gtk-greeter

wm:
awesome-git rofi lm_sensors acpid jq fortune-mod redshift mpd mpc maim feh light-git pulseaudio inotify-tools xdotool picom

cli-tools:
tmux zsh bat mcfly git-delta-git lsd zoxide tty-clock pomo nvm docker python3 python-pip python-virtualenv xsel

window tools:
firefox kitty obsidian


note: some of these things (especially the slow to compile rust CLI tools) could probably wait
until some further step after setup_dotfiles.sh, but what we have works


## setup_dotfiles.sh

Copy various git repositories from the web to get things working (oh-my-zsh, powerlevel10k, etc..) and
setup the various dotfiles to work.

Take some inspiration from "do nothing scripting" for the manual steps.

TO DO: Handle symlinking folders that already exist a bit better


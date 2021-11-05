# Bootstrap

The purpose of this folder is to provide scripts to automate the setup of a new environment with my various dotfiles

Files are:
## setup_and_install_arch.sh

From a minimal arch installation, end up with everything installed.

Installs:
base:
base base-devel neovim git openssh archlinux-keyring fuse

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



## setup_dotfiles.sh

Copy various git repositories from the web to get things working (oh-my-zsh, powerlevel10k, etc..) and
setup the various dotfiles to work.

Take some inspiration from "do nothing scripting" for the manual steps.

Steps are:
- Setup ssh key (id_rsa from bitwarden)
- copy wallhaven.json from bitwarden
- clone git repos below
- copy/symlink files from dotfiles and elenapandotfiles to correct locations in home
- Add user to groups
- setup nvm
- setup ucee tool
- setup neovim
- set rofi theme

git repos to clone:
https://github.com/elenapan/dotfiles.git ~/otherrepos/elenapandotfiles
https://github.com/lr-tech/rofi-themes-collection ~/otherrepos/rofi-themes-collection
https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
https://github.com/davidde/git ~/.oh-my-zsh/custom/plugins/git
https://github.com/djui/alias-tips ~/.oh-my-zsh/custom/plugins/alias-tips
https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git@github.com:triorph/fast-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/git
git@github.com:triorph/obsidian ~/obsidian
git@its-git.canterbury.ac.nz:student-first/ucee.git ~/ucee

#!/bin/bash
# Sets up a clean home environment for a user from the dotfiles
#
# This script assumes all needed packages are already installed. For Arch this is handled via the setup script.
#
# Steps are:
# - Get id_rsa from bitwarden (manual step)
# - get wallhaven.json from bitwarden (manual step)
# - clone repos from the web
# - Copy/symlink files
# - load fonts
# - Add user to groups
# - setup nvm
# - setup ucee tool
# - setup neovim (manual step)
# - set rofi theme (manual step)
echo ""
echo "This script should be run in a way that you can use multiple terminals at once."
echo "Either in a Window Manager, or with access to terminal multiplexing with something like tmux."
echo ""
echo "Step 1: Setting up SSH keys for private git access"
echo "Manual step: Copy id_rsa (from bitwarden) to ~/.ssh/id_rsa (press enter once done)"
mkdir ~/.ssh
cp ~/dotfiles/bootstrap/id_rsa.pub ~/.ssh/id_rsa.pub
read varname
echo ""
echo "Step 2: Setup the config for wallhaven access"
echo "Manual step: copy wallhaven.json (from bitwarden) to ~/.config/wallhaven.json (press enter once done)"
mkdir ~/.config
read varname
echo ""
echo "Step 3: Cloning repos from the web"
echo ""
mkdir ~/otherrepos
git clone https://github.com/elenapan/dotfiles.git ~/otherrepos/elenapandotfiles
git clone https://github.com/lr-tech/rofi-themes-collection ~/otherrepos/rofi-themes-collection
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
git clone https://github.com/davidde/git ~/.oh-my-zsh/custom/plugins/git
git clone https://github.com/djui/alias-tips ~/.oh-my-zsh/custom/plugins/alias-tips
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone git@github.com:triorph/fast-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/git
git clone git@github.com:triorph/obsidian ~/obsidian
git clone git@its-git.canterbury.ac.nz:student-first/ucee.git ~/ucee
echo ""
echo "Step 3 complete."
echo ""
echo "Step 4: Copy/symlink files"
echo ""
mkdir ~/.local
mkdir ~/.local/bin
mkdir ~/.config/kitty
mkdir ~/.config/git
ln -s ~/dotfiles/bin/newwp ~/.local/bin/newwp
cp -rv ~/otherrepos/elenapandotfiles/config/awesome ~/.config/awesome
cp -rv ~/otherrepos/elenapandotfiles/bin/* ~/.local/bin/
rm ~/.config/awesome/keys.lua
rm ~/.config/awesome/rc.lua
ln -s ~/dotfiles/config/awesome/keys.lua ~/.config/awesome/keys.lua
ln -s ~/dotfiles/config/awesome/rc.lua ~/.config/awesome/rc.lua
ln -s ~/dotfiles/config/bat ~/.config/bat
ln -s ~/dotfiles/config/git/gitattributes ~/.gitattributes
cp ~/dotfiles/config/git/gitconfig ~/.gitconfig
ln -s ~/dotfiles/config/git/ignore ~/.config/git/ignore
ln -s ~/dotfiles/config/kitty/dracula.conf ~/.config/kitty/dracula.conf
ln -s ~/dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
ln -s ~/dotfiles/config/nvim ~/.config/nvim
ln -s ~/dotfiles/config/tmux/tmux.conf ~/.tmux
ln -s ~/dotfiles/config/zsh/custom_plugin ~/.oh-my-zsh/custom/plugins/miek-aliases-etc
ln -s ~/dotfiles/config/zsh/p10k.zsh ~/.p10k.zsh
ln -s ~/dotfiles/config/zsh/zshrc ~/.zshrc
mkdir ~/.fonts
cp -rv ~/otherrepos/elenapandotfiles/misc/fonts/* ~/.fonts
cp -rv ~/dotfiles/fonts/* ~/.fonts
mkdir ~/.config/picom
touch ~/.config/picom/picom.conf
mkdir -p ~/.local/share/rofi/themes/
cp ~/otherrepos/rofi-themes-collection/themes/* ~/.local/share/rofi/themes
echo ""
echo "Step 4 complete."
echo ""
echo "Step 5: load fonts"
echo ""
fc-cache -v
echo ""
echo "Step 5 complete"
echo ""
echo "Step 6: Add user to groups (requires sudo access)"
echo ""
sudo usermod -aG docker nologinpasswd autologin $USER
echo ""
echo "Step 6 complete"
echo ""
echo "Step 7: Setup nvm"
sh /usr/share/nvm/init-nvm.sh
nvm install --lts
echo ""
echo "Step 7 complete"
echo ""
echo "Step 8: setup ucee tool"
echo ""
cd ~/ucee
./bootstrap.sh
cd ~/
echo ""
echo "Step 7 complete"
echo ""
echo "Step 8: setup neovim"
echo "Manual step: Enter \"nvim\" and run the setup commands to get it working. These are:"
echo ":lua require(\"plugins\")"
echo ":PackerSync"
echo ":CHADdeps"
echo ":COQdeps"
echo ":COQsnips compile"
echo "then once all run, close neovim (:q!), reopen and run:"
echo ":PackerCompile"
echo "and close again (:q!)"
echo "Press enter once done"
read varname
echo ""
echo "Step 9: Set rofi theme"
echo "Manual step: open rofi-theme-selector and choose the theme you want (I usually use dark rounded pink)"
echo "Press enter once done"
read varname
echo ""
echo "Setup complete! You may have to restart your window-manager / reboot for this to take effect"
echo ""

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
# - setup neovim (manual step)
# - set rofi theme (manual step)
# - Install LSPs
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
mkdir ~/repos
#git clone https://github.com/elenapan/dotfiles.git ~/otherrepos/elenapandotfiles
#git clone https://github.com/lr-tech/rofi-themes-collection ~/otherrepos/rofi-themes-collection
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
git clone https://github.com/davidde/git ~/.oh-my-zsh/custom/plugins/git
git clone https://github.com/djui/alias-tips ~/.oh-my-zsh/custom/plugins/alias-tips
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting
#git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
#git clone git@github.com:triorph/notes.git ~/org
#git clone git@github.com:triorph/newwp.git ~/repos/newwp
#git clone https://github.com/sumneko/lua-language-server ~/otherrepos/lua-language-server
#git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
#cd ~/otherrepos/lua-language-server
#git submodule update --init --recursive
cd ~/dotfiles
#git remote remove origin
#git remote add origin git@github.com:/triorph/dotfiles.git
echo ""
echo "Step 3 complete."
echo ""
echo "Step 4: Copy/symlink files"
echo ""
mkdir ~/.local
mkdir ~/.local/bin
mkdir ~/.config/kitty
mkdir ~/.config/git
cd ~/repos/newwp
cargo install --path .
ln -s ~/dotfiles/bin/set_daymode.sh ~/.local/bin/set_daymode
ln -s ~/dotfiles/bin/set_nightmode.sh ~/.local/bin/set_nightmode
ln -s ~/dotfiles/bin/toggle_daynight.sh ~/.local/bin/toggle_daynight
#cp -r ~/otherrepos/elenapandotfiles/config/awesome ~/.config/awesome
#cp -r ~/otherrepos/elenapandotfiles/bin/* ~/.local/bin/
#rm ~/.config/awesome/keys.lua
#rm ~/.config/awesome/rc.lua
#rm ~/.config/awesome/elemental/bar/ephemeral.lua
#rm ~/.config/awesome/themes/amarena/theme.lua
#ln -s ~/dotfiles/config/awesome/keys.lua ~/.config/awesome/keys.lua
#ln -s ~/dotfiles/config/awesome/rc.lua ~/.config/awesome/rc.lua
#ln -s ~/dotfiles/config/awesome/ephemeralbar.lua ~/.config/awesome/elemental/bar/ephemeral.lua
#ln -s ~/dotfiles/config/awesome/theme.lua ~/.config/awesome/themes/amarena/theme.lua
ln -s ~/dotfiles/config/bat ~/.config
ln -s ~/dotfiles/config/git/gitattributes ~/.gitattributes
cp ~/dotfiles/config/git/gitconfig ~/.gitconfig
ln -s ~/dotfiles/config/git/ignore ~/.config/git/ignore
ln -s ~/dotfiles/config/kitty/kitty-linux.conf ~/.config/kitty/kitty.conf
ln -s ~/dotfiles/config/kitty/kitty-common.conf ~/.config/kitty/kitty-common.conf
ln -s ~/dotfiles/config/kitty/font-linux.conf ~/.config/kitty/font-linux.conf
ln -s ~/dotfiles/config/nvim ~/.config
ln -s ~/dotfiles/config/tmux/tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/config/zsh/miek-aliases-etc ~/.oh-my-zsh/custom/plugins
ln -s ~/dotfiles/config/zsh/p10k.zsh ~/.p10k.zsh
ln -s ~/dotfiles/config/zsh/zshrc ~/.zshrc
ln -s ~/dotfiles/config/zsh/zshenv ~/.zshenv
ln -s ~/dotfiles/config/prettierrc.json ~/.prettierrc.json
ln -s ~/dotfiles/config/doom ~/.doom.d
mkdir ~/.fonts
#cp -r ~/otherrepos/elenapandotfiles/misc/fonts/* ~/.fonts
cp -r ~/dotfiles/fonts/* ~/.fonts
#mkdir ~/.config/picom
#touch ~/.config/picom/picom.conf
#mkdir -p ~/.local/share/rofi/themes/
#cp ~/otherrepos/rofi-themes-collection/themes/* ~/.local/share/rofi/themes
if [[ ! -f ~/.local/bin/nvim ]]; then
    curl -fsSL https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage > ~/.local/bin/nvim
    chmod a+x ~/.local/bin/nvim
fi
echo "source ~/.zshenv" > ~/.xprofile
echo "Changing shell to zsh (may require password)"
#chsh -s /bin/zsh
echo ""
echo "Please set your kitty theme `kitty +kitten themes`"
echo ""
read varname
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
sudo usermod -aG docker $USER
sudo usermod -aG nopasswdlogin $USER
sudo usermod -aG autologin $USER
echo ""
echo "Step 6 complete"
echo ""
echo "Step 7: Setup nvm"
sh /usr/share/nvm/init-nvm.sh
. ~/.nvm/nvm.sh
nvm install --lts
echo ""
echo "Step 7 complete"
echo ""
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
echo "Step 10: Install LSPs"
echo ""
npm install -g pyright
npm install -g typescript-language-server
npm install -g eslint_d
npm install -g @fsouza/prettierd
npm install -g prettier
if [[ ! -f ~/.local/bin/rust-analyzer ]]; then
    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
    chmod +x ~/.local/bin/rust-analyzer
fi
echo "Manual step: Install the sumneko_lua LSP and symlink to correct place"
echo ""
echo "cd ~/otherrepos/lua-language-server"
echo "cd 3rd/luamake"
echo "./compile/install.sh"
echo "cd ../../"
echo "3rd/luamake/luamake rebuild"
echo "ln -s ~/otherrepos/lua-language-server ~/.local/share/lua-language-server"
echo ""
echo "Press enter to continue"
read varname
echo ""
echo "Step 10 complete"
echo ""
echo ""
echo ""
echo "Step 11: Manual step, since it takes so long. Please install doom emacs from the command line with `doom install`"
echo "press enter to continue"
read varname
echo "Step 11 complete"
echo ""
echo "Setup complete! You may have to restart your window-manager / reboot for this to take effect"
echo ""

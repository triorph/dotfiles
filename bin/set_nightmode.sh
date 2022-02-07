#!/bin/bash
kitty +kitten themes Tokyo Night
sed -i "s/^vim.cmd(\[\[set background=.*\]\])/-- vim.cmd([[set background=light]])/" ~/.config/nvim/lua/config/colour.lua
sed -i "s/vim.cmd(\[\[colorscheme .*\]\])/vim.cmd([[colorscheme tokyonight]])/" ~/.config/nvim/lua/config/colour.lua
sed -i "s/--theme=\".*\"/--theme=\"gruvbox-dark\"/" ~/.config/bat/config
sed -i "s/syntax-theme = .*/syntax-theme = gruvbox-dark/" ~/.gitconfig

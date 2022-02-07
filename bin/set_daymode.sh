#!/bin/bash
kitty +kitten themes Gruvbox Light
sed -i "s/-- vim.cmd(\[\[set background=.*\]\])/vim.cmd([[set background=light]])/" ~/.config/nvim/lua/config/colour.lua
sed -i "s/vim.cmd(\[\[colorscheme .*\]\])/vim.cmd([[colorscheme gruvbox]])/" ~/.config/nvim/lua/config/colour.lua
sed -i "s/--theme=\".*\"/--theme=\"gruvbox-light\"/" ~/.config/bat/config
sed -i "s/syntax-theme = .*/syntax-theme = gruvbox-light/" ~/.gitconfig

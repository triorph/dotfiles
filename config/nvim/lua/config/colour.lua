-- Installed colour scheme options
-- tokyonight (with storm, night and day variants)
-- nightfox (with nordfox, nightfox and duskfox, dayfox, dawnfox variants)
-- catppuccin (with latte, frappe, macchiato and mocha flavours)
-- rose-pine (with base, moon, dawn variants)
-- gruvbox (with set background light or dark)
-- boo
-- kanagawa
vim.g.tokyonight_style = "night" -- options are storm, night and day
vim.g.tokyonight_italic_functions = true
vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
vim.g.tokyonight_italic_comments = true
vim.g.rose_pine_variant = "moon" -- options are  "base", "moon", and "dawn"
-- vim.g.catppuccin_flavour = "mocha" -- options are "frappe", "latte", "macchiato", and "mocha"

-- Load the colorscheme
-- vim.cmd([[set background=light]])
vim.cmd([[colorscheme catppuccin-mocha]])

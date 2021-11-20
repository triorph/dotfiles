-- Installed colour scheme options
-- tokyonight (with storm, night and day variants)
-- nightfox (with nordfox, nightfox and palefox variants)
-- catppuccino (with soft_manilo, dark_catppuccino, neon_latte and light_melya options)
-- rose-pine (with base, moon, dawn variants)
-- gruvbox
-- boo
vim.g.tokyonight_style = "storm" -- options are storm, night and day
vim.g.tokyonight_italic_functions = true
vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
vim.g.tokyonight_italic_comments = true
vim.g.rose_pine_variant = "moon" -- options are  "base", "moon", and "dawn"
-- local nightfox = require("nightfox")
--[[ nightfox.setup({
	fox = "nightfox", -- options are "nordfox", "nightfox", and "palefox"
}) ]]

-- Load the colorscheme
vim.cmd([[colorscheme rose-pine]])

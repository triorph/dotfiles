vim.g.tokyonight_style = "storm" -- options are storm, night and day
vim.g.tokyonight_italic_functions = true
vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
local nightfox = require("nightfox")
nightfox.setup({
	fox = "nightfox", -- options are "nordfox", "nightfox", and "palefox"
})

-- Load the colorscheme
vim.cmd([[colorscheme nightfox]])

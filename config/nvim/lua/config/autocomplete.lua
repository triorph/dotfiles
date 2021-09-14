vim.o.completeopt = "menuone,noselect"
vim.g.coq_settings = { ["auto_start"] = "shut-up" }
local opts = { silent = true, noremap = true }

require("nvim-treesitter.configs").setup({
	matchup = { enable = true },
})

require("coq")
vim.cmd([[COQnow --shut-up]])

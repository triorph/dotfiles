vim.o.termguicolors = true
vim.o.syntax = "on"
vim.o.errorbells = false
vim.o.smartcase = true
vim.o.showmode = false
vim.bo.swapfile = false
vim.o.backup = false
vim.o.undodir = vim.fn.stdpath("config") .. "/undodir"
vim.o.undofile = true
vim.o.incsearch = true
vim.o.hidden = true
vim.o.scrolloff = 10
vim.o.autoread = true
vim.bo.autoindent = true
vim.bo.smartindent = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smarttab = true
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = "yes"
vim.wo.wrap = false
vim.o.cursorcolumn = true
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.g.pyindent_open_paren = vim.o.shiftwidth
-- limit the autocomplete popup menu size (a pet peeve of mine is how often the autocomplete blocks what you actually want to see)
vim.o.pumheight = 5
vim.cmd([[set colorcolumn=81,121]])

vim.cmd([[ ab breakpiont breakpoint ]])
vim.cmd([[ autocmd filetype python setlocal colorcolumn=89 ]])

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

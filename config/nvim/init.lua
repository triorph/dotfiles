vim.g.do_filetype_lua = 1
vim.g.did_load_filetypes = 0
pcall(require, "options")
pcall(require, "config/keymappings")

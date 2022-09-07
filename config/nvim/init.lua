vim.g.do_filetype_lua = 1
vim.opt.guifont = "JetBrainsMono Nerd Font Mono" .. ":h17"
vim.cmd[[set fillchars+=diff:╱]]
pcall(require, "options")
pcall(require, "config/keymappings")

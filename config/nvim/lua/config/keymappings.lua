local key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true, silent = true })
end
local verbal_key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true })
end
local ncmdmap = function(key, cmd)
	key_mapper("n", key, "<cmd>" .. cmd .. "<CR>")
end
-- usually if I press multiple jj or kk it means I forgot I was in insert mode
key_mapper("i", "jj", "<ESC>")
key_mapper("i", "kk", "<ESC>")
key_mapper("i", "jk", "<ESC>")
-- telescope simple shortcuts
ncmdmap("<leader>b", "Telescope buffers")
ncmdmap("<leader>p", "Telescope neoclip")
ncmdmap("<leader>tp", "Telescope find_files")
ncmdmap("<leader>t/", "Telescope live_grep")
ncmdmap("<leader>tf", "Telescope file_browser")
-- commenting
vim.api.nvim_set_keymap("n", "<leader>/", "gcc", { silent = true })
vim.api.nvim_set_keymap("v", "<leader>/", "gc", { silent = true })

-- ZenMode
ncmdmap("<leader>vz", "ZenMode")

--  Copy to clipboard
verbal_key_mapper("v", "\\y", '"+y')
verbal_key_mapper("n", "\\Y", '"+yg_')
verbal_key_mapper("n", "\\y", '"+y')

--  Paste from clipboard
verbal_key_mapper("n", "\\p", '"+p')
verbal_key_mapper("n", "\\P", '"+P')
verbal_key_mapper("v", "\\p", '"+p')
verbal_key_mapper("v", "\\P", '"+P')

-- Glow markdown preview
ncmdmap("<leader>vg", "Glow")

-- primagen move visual chunk
key_mapper("v", "J", ":m '>+1<CR>gv=gv")
key_mapper("v", "K", ":m '<-2<CR>gv=gv")

-- MaskDask change same text again
vim.api.nvim_set_keymap("n", "cg*", "*Ncgn", { silent = true })
key_mapper("n", "g.", '/\\V\\C<C-r>"<CR>cgn<C-a><Esc>')

-- Undo F1 as I keep hitting it accidentally when trying to hit ESC for exiting insert mode (less of a problem after capslock mapping)
key_mapper("n", "<F1>", "<Nop>")
key_mapper("i", "<F1>", "<Nop>")

-- Overwrite the packer commands to work without packer directly loaded (for lazy loading) (borrowed from nvchad)
vim.cmd("silent! command PackerCompile lua require 'plugins' require('packer').compile()")
vim.cmd("silent! command PackerInstall lua require 'plugins' require('packer').install()")
vim.cmd("silent! command PackerStatus lua require 'plugins' require('packer').status()")
vim.cmd("silent! command PackerSync lua require 'plugins' require('packer').sync()")
vim.cmd("silent! command PackerUpdate lua require 'plugins' require('packer').update()")

ncmdmap("<leader>sr", "source ~/.config/nvim/lua/init.lua")

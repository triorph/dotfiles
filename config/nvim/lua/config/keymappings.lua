local key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true, silent = true })
end
local verbal_key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true })
end
local ncmdmap = function(key, cmd)
	key_mapper("n", key, "<cmd>" .. cmd .. "<CR>")
end
require("legendary").setup()
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
vim.keymap.set("n", "<Esc>", function()
	require("notify").dismiss() -- clear notifications
	vim.cmd.nohlsearch() -- clear highlights
	vim.cmd.echo() -- clear short-message
end)

-- Undo F1 as I keep hitting it accidentally when trying to hit ESC for exiting insert mode (less of a problem after capslock mapping)
key_mapper("n", "<F1>", "<Nop>")
key_mapper("i", "<F1>", "<Nop>")

-- Auto-split on commas (with auto-indent), in case you don't have autoformatting setup.
-- TODO: some version of this that checks that the , is of type @punctiation.delimiter (might have to make a custom method)
key_mapper("n", "<leader>,", ":s/,/,\\r/g<CR>`[v`]=<CR><Esc>:nohl<CR>")

-- Overwrite the packer commands to work without packer directly loaded (for lazy loading) (borrowed from nvchad)
vim.cmd("silent! command PackerCompile lua require 'plugins' require('packer').compile()")
vim.cmd("silent! command PackerInstall lua require 'plugins' require('packer').install()")
vim.cmd("silent! command PackerStatus lua require 'plugins' require('packer').status()")
vim.cmd("silent! command PackerSync lua require 'plugins' require('packer').sync()")
vim.cmd("silent! command PackerUpdate lua require 'plugins' require('packer').update()")

-- Git status
ncmdmap("<leader>g", "Ge:")
-- Resource my init.lua
ncmdmap("<leader>sr", "source ~/.config/nvim/init.lua")
-- vim.ui.select({ 'tabs', 'spaces' }, { prompt = 'Select tabs or spaces:', format_item = function(item) return "I'd like to choose " .. item end, }, function(choice) if choice == 'spaces' then vim.o.expandtab = true else vim.o.expandtab = false end end)

-- basic navigation if lsp isn't present
ncmdmap("gF", "Telescope grep_string")

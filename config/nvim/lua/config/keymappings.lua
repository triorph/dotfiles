local key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true, silent = true })
end
local verbal_key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(mode, key, result, { noremap = true })
end
-- usually if I press multiple jj or kk it means I forgot I was in insert mode
key_mapper("i", "jj", "<ESC>")
key_mapper("i", "kk", "<ESC>")
key_mapper("i", "jk", "<ESC>")
-- CHADTree
key_mapper("n", "<F3>", "<cmd>CHADopen<CR>")
-- telescope simple shortcuts
key_mapper("n", "<leader>b", "<cmd>Telescope buffers<CR>")
--[[ key_mapper("n", "<c-p>", "<cmd>Telescope find_files<CR>") -- lets try not using these 2 so I can keep their original usage available
key_mapper("n", "<c-f>", "<cmd>Telescope live_grep<CR>") ]]
key_mapper("n", "<leader>p", "<cmd>Telescope neoclip<CR>")
key_mapper("n", "<leader>tp", "<cmd>Telescope find_files<CR>")
key_mapper("n", "<leader>tf", "<cmd>Telescope live_grep<CR>")
key_mapper("n", "<leader>tb", "<cmd>Telescope buffers<CR>")
-- kommentary
require("kommentary.config") -- .use_extended_mappings()
vim.api.nvim_set_keymap("n", "<leader>/", "gcc", { silent = true })
vim.api.nvim_set_keymap("v", "<leader>/", "gc", { silent = true })

-- ZenMode
key_mapper("n", "<leader>vz", "<cmd>ZenMode<CR>")

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
key_mapper("n", "<leader>vg", "<cmd>Glow<CR>")

-- primagen move visual chunk
key_mapper("v", "J", ":m '>+1<CR>gv=gv")
key_mapper("v", "K", ":m '<-2<CR>gv=gv")

-- MaskDask change same text again
vim.api.nvim_set_keymap("n", "cg*", "*Ncgn", { silent = true })
key_mapper("n", "g.", '/\\V\\C<C-r>"<CR>cgn<C-a><Esc>')

-- Overwrite the packer commands to work without packer directly loaded (for lazy loading) (borrowed from nvchad)
vim.cmd("silent! command PackerCompile lua require 'plugins' require('packer').compile()")
vim.cmd("silent! command PackerInstall lua require 'plugins' require('packer').install()")
vim.cmd("silent! command PackerStatus lua require 'plugins' require('packer').status()")
vim.cmd("silent! command PackerSync lua require 'plugins' require('packer').sync()")
vim.cmd("silent! command PackerUpdate lua require 'plugins' require('packer').update()")

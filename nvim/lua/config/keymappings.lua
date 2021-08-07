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
-- easy insert lines
key_mapper("n", "<C-o>", "o<ESC>")

-- telescope simple shortcuts
key_mapper("n", "<c-p>", "<cmd>Telescope find_files<CR>")
key_mapper("n", "<c-f>", "<cmd>Telescope live_grep<CR>")
-- kommentary
require("kommentary.config") -- .use_extended_mappings()
-- ZenMode
key_mapper("n", "<F11>", "<cmd>ZenMode<CR>")

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
key_mapper("n", "<leader>p", "<cmd>Glow<CR>")

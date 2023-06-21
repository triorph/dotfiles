vim.opt.termguicolors = true
local bufferline = require("bufferline")
bufferline.setup({
	options = {
		mode = "buffers", -- set to "tabs" to only show tabpages instead
		style_preset = bufferline.style_preset.default, -- or bufferline.style_preset.minimal,
		themable = false, -- allows highlight groups to be overriden i.e. sets highlights as default
		numbers = "ordinal",
		close_command = "bdelete! %d",
		right_mouse_command = nil,
		left_mouse_command = "buffer %d",
		middle_mouse_command = "bdelete! %d",
		indicator = {
			style = "none",
		},
		buffer_close_icon = "󰅖",
		modified_icon = "●",
		close_icon = "",
		left_trunc_marker = "",
		right_trunc_marker = "",
		max_name_length = 18,
		max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
		truncate_names = true, -- whether or not tab names should be truncated
		tab_size = 18,
		diagnostics = "nvim_lsp",
		diagnostics_update_in_insert = false,
		-- The diagnostics indicator can be set to nil to keep the buffer name highlight but delete the highlighting
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			return "(" .. count .. ")"
		end,
		color_icons = true, -- whether or not to add the filetype icon highlights
		show_buffer_icons = true, -- disable filetype icons for buffers
		show_buffer_close_icons = true,
		show_close_icon = true,
		show_tab_indicators = true,
		show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
		persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
		-- can also be a table containing 2 custom separators
		-- [focused and unfocused]. eg: { '|', '|' }
		separator_style = "slant",
		hover = {
			enabled = true,
			delay = 200,
			reveal = { "close" },
		},
	},
})
vim.api.nvim_set_keymap("n", "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>4", "<cmd>BufferLineGoToBuffer 4<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>5", "<cmd>BufferLineGoToBuffer 5<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>6", "<cmd>BufferLineGoToBuffer 6<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>7", "<cmd>BufferLineGoToBuffer 7<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>8", "<cmd>BufferLineGoToBuffer 8<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>9", "<cmd>BufferLineGoToBuffer 9<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader><leader>", "<c-^>", { silent = true, noremap = true })

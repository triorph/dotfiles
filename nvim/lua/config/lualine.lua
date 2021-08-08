require("lualine").setup({
	options = {
		theme = "tokyonight",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },
		lualine_c = {
			"filename",
			{
				"diagnostics",
				sources = { "nvim_lsp" },
			},
		},
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	extensions = { "quickfix" },
})

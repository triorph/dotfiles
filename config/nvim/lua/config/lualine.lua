require("lualine").setup({
	options = {
		-- theme = "tokyonight",
		-- theme = "gruvbox",
		-- theme = "catppuccino",
		-- theme = "nightfox",
		theme = "rose-pine",
		-- theme = "kanagawa",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },
		lualine_c = {
			"filename",
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
			},
		},
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	extensions = { "quickfix" },
})

local function lint_results()
	local bufnr = vim.g.actual_curbuf
	return vim.fn["neomake#statusline#get"](bufnr)
end
require("lualine").setup({
	options = {
		-- theme = "tokyonight",
		-- theme = "gruvbox",
		-- theme = "tokyonight",
		-- theme = "catppuccino",
		theme = "rose-pine",
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
			{
				lint_results,
			},
		},
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	extensions = { "quickfix" },
})

-- vim.g.indent_blankline_char_highlight_list = {"Error", "Function"}
vim.g.indent_blankline_show_current_context = true
vim.g.indent_blankline_filetype_exclude = { "dashboard" }

require("indent_blankline").setup({
	char = "|",
	buftype_exclude = { "terminal", "dashboard", "startify", "alpha" },
})

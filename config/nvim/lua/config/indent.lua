require("indent_blankline").setup({
	char = "|",
	show_current_context = true,
	buftype_exclude = { "terminal", "dashboard", "startify", "alpha" },
	filetype_exclude = { "dashboard", "alpha", "CHADTree" },
})

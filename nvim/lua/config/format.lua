require("format").setup({
	["*"] = {
		{ cmd = { "sed -i 's/[ \t]*$//'" } }, -- remove trailing whitespace
	},
	vim = {
		{
			cmd = { "luafmt -w replace" },
			start_pattern = "^lua << EOF$",
			end_pattern = "^EOF$",
		},
	},
	python = {
		{
			cmd = { "black" },
		},
	},
	vimwiki = {
		{
			cmd = { "prettier -w --parser babel" },
			start_pattern = "^{{{javascript$",
			end_pattern = "^}}}$",
		},
	},
	lua = {
		{
			cmd = { "stylua" },
		},
	},
	json = {
		{ cmd = { "prettier -w" } },
	},
	go = {
		{
			cmd = { "gofmt -w", "goimports -w" },
			tempfile_postfix = ".tmp",
		},
	},
	javascript = {
		{ cmd = { "prettier -w", "./node_modules/.bin/eslint --fix" } },
	},
	markdown = {
		{ cmd = { "prettier -w" } },
		{
			cmd = { "black" },
			start_pattern = "^```python$",
			end_pattern = "^```$",
			target = "current",
		},
	},
})
vim.cmd([[augroup Format
    autocmd!
    autocmd BufWritePost * FormatWrite
augroup END]])

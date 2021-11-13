require("format").setup({
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
	lua = {
		{
			cmd = { "stylua" },
		},
	},
	json = {
		{ cmd = { "prettier -w --tab-width 4" } },
	},
	javascript = {
		{ cmd = { "prettier -w", "./node_modules/.bin/eslint --fix" } },
	},
	typescript = {
		{ cmd = { "prettier -w", "./node_modules/.bin/eslint --fix" } },
	},
	html = {
		{ cmd = { "prettier -w" } },
	},
	css = { { cmd = { "prettier -w" } } },
	markdown = {
		{ cmd = { "prettier -w" } },
		{
			cmd = { "black" },
			start_pattern = "^```python$",
			end_pattern = "^```$",
			target = "current",
		},
	},
	rust = {
		{ cmd = { "rustfmt" } },
	},
})
vim.cmd([[augroup Format
    autocmd!
    autocmd BufWritePost * FormatWrite
augroup END]])

-- remove trailing whitespaces in vim as a BufWritePre
vim.cmd([[
    autocmd BufWritePre * :%s/\s\+$//e
    ]])

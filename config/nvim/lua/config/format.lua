require("null-ls").setup({
	sources = {
		require("null-ls").builtins.formatting.stylua,
		require("null-ls").builtins.formatting.isort,
		require("null-ls").builtins.formatting.black,
		require("null-ls").builtins.formatting.prettierd,
		require("null-ls").builtins.diagnostics.eslint_d,
		require("null-ls").builtins.diagnostics.pylama.with({
			extra_args = { "--linters=print,mccabe,pycodestyle,pyflakes", "--ignore=E501,W0612,W605,E231,E203" },
		}),
		require("null-ls").builtins.completion.spell,
	},
	on_attach = function(client)
		if client.resolved_capabilities.document_formatting then
			vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 5000)")
		end
	end,
})

-- remove trailing whitespaces in vim as a BufWritePre
vim.cmd([[
    autocmd BufWritePre * :%s/\s\+$//e
    ]])

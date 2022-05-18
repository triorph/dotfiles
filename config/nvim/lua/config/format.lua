local group = vim.api.nvim_create_augroup("DocumentFormatting", { clear = true })
require("null-ls").setup({
	sources = {
		require("null-ls").builtins.formatting.stylua,
		require("null-ls").builtins.formatting.isort.with({
			extra_args = { "--profile=black" },
		}),
		require("null-ls").builtins.formatting.black,
		require("null-ls").builtins.formatting.prettierd,
		require("null-ls").builtins.diagnostics.eslint_d,
		require("null-ls").builtins.diagnostics.pylama.with({
			extra_args = { "--linters=print,mccabe,pycodestyle,pyflakes", "--ignore=E501,W0612,W605,E231,E203" },
		}),
		-- require("null-ls").builtins.completion.spell,
	},
	on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = group,
                buffer = bufnr,
                callback = function()
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.formatting_sync(nil, 5000)
                end,
            })
        end
    end,
})

-- remove trailing whitespaces in vim as a BufWritePre
vim.api.nvim_create_autocmd("BufWritePre", { command = ":%s/\\s\\+$//e", group = "DocumentFormatting" })

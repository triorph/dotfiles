local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local checkstyle = h.make_builtin({
	name = "checkstyle",
	meta = {
		description = "Generic code quality linter",
	},
	method = DIAGNOSTICS,
	filetypes = { "java" },
	generator_opts = {
		command = "checkstyle",
		args = {
			"-c",
			u.get_root() .. "/checkstyle-rules.xml",
			"$FILENAME",
		},
		to_stdin = false,
		from_stderr = false,
		to_temp_file = false,
		format = "line",
		on_output = h.diagnostics.from_patterns({
			{
				pattern = [[.(%w+).*:(%d+):(%d+): (.+)]],
				groups = { "code", "row", "col", "message" },
			},
		}),
	},
	factory = h.generator_factory,
})
local group = vim.api.nvim_create_augroup("DocumentFormatting", { clear = true })
require("null-ls").setup({
	debug = true,
	sources = {
		require("null-ls").builtins.formatting.stylua,
		require("null-ls").builtins.formatting.isort.with({
			extra_args = { "--profile=black" },
		}),
		-- require("null-ls").builtins.formatting.google_java_format,
		require("null-ls").builtins.formatting.black,
		require("null-ls").builtins.formatting.prettier,
		require("null-ls").builtins.diagnostics.eslint_d,
		require("null-ls").builtins.diagnostics.pylama.with({
			extra_args = { "--linters=print,mccabe,pycodestyle,pyflakes", "--ignore=E501,W0612,W605,E231,E203" },
		}),
		checkstyle,
		-- require("null-ls").builtins.completion.spell,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
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

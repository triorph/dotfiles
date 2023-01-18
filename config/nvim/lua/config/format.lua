local builtins = require("null-ls").builtins

local group = vim.api.nvim_create_augroup("DocumentFormatting", { clear = true })
require("null-ls").setup({
	debug = true,
	sources = {
		builtins.formatting.stylua,
		builtins.formatting.isort.with({
			extra_args = { "--profile=black" },
		}),
		builtins.formatting.black,
		builtins.diagnostics.shellcheck,
		builtins.formatting.prettier.with({
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"css",
				"scss",
				"less",
				"html",
				"json",
				"jsonc",
				"markdown",
				"graphql",
				"handlebars",
			},
		}),
		builtins.diagnostics.eslint,
		builtins.diagnostics.pylama.with({
			extra_args = { "--linters=print,mccabe,pycodestyle,pyflakes", "--ignore=E501,W0612,W605,E231,E203" },
		}),
		builtins.diagnostics.checkstyle.with({
			extra_args = {
				"-c",
				"./checkstyle-rules.xml",
			},
			condition = function(utils)
				return utils.root_has_file({ "checkstyle-rules.xml" })
			end,
			env = {
				JAVA_HOME = vim.env.HOME .. "/.asdf/installs/java/openjdk-19",
			},
		}),
		-- require("null-ls").builtins.completion.spell,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = group,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({
						bufnr = bufnr,
						filter = function(filter_client)
							return filter_client.name == "null-ls"
						end,
					})
				end,
			})
		end
	end,
})

-- remove trailing whitespaces in vim as a BufWritePre
vim.api.nvim_create_autocmd("BufWritePre", { command = ":%s/\\s\\+$//e", group = "DocumentFormatting" })

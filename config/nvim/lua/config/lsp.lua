require("lspsaga").init_lsp_saga()
local nvim_lsp = require("lspconfig")

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local group = vim.api.nvim_create_augroup("DocumentFormatting", { clear = true })
local on_attach = function(client, bufnr)
	vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
	if client.resolved_capabilities.document_formatting then
		vim.api.nvim_create_autocmd(
			"BufWritePre",
			{ command = "lua vim.lsp.buf.formatting_sync(nil, 5000)", group = "DocumentFormatting", buffer = bufnr }
		)
	end

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	--Enable completion triggered by <c-x><c-o>
	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings.
	local opts = { noremap = true, silent = true }

	-- See `:help vim.lsp.*` for documentation on any of the below functions
	-- buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	--  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
	buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
	buf_set_keymap("n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
	buf_set_keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	buf_set_keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	-- buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
	buf_set_keymap("n", "<space>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
	buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<space>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
	buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

local on_attach_no_format = function(client, bufnr)
	client.resolved_capabilities.document_formatting = false
	client.resolved_capabilities.document_range_formatting = false
	on_attach(client, bufnr)
end

vim.diagnostic.config({
	virtual_text = {
		severity = { min = vim.diagnostic.severity.WARN },
	},
})

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "pyright", "terraform-lsp",  }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup({
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 150,
		},
	})
end
nvim_lsp.tsserver.setup({
	on_attach = on_attach_no_format,
	flags = { debounce_text_changes = 150 },
})
local sumneko_root_path = vim.env.HOME .. "/.local/share/lua-language-server"
local runtime_path = vim.split(package.path, ";")
local sumneko_binary = sumneko_root_path .. "/bin/lua-language-server"
nvim_lsp.sumneko_lua.setup({
	on_attach = on_attach_no_format,
	flags = {
		debounce_text_changes = 150,
	},
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = runtime_path,
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				preloadFileSize = 200,
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
	cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
})

nvim_lsp.rust_analyzer.setup({
	on_attach = on_attach,
	flags = {
		debounce_text_changes = 150,
	},
	settings = {
		["rust-analyzer"] = {
			assist = {
				importMergeBehavior = "last",
				importPrefix = "by_self",
			},
			diagnostics = {
				disabled = { "unresolved-import" },
			},
			cargo = {
				loadOutDirsFromCheck = true,
			},
			procMacro = {
				enable = true,
			},
			checkOnSave = {
				command = "clippy",
			},
		},
	},
})

-- LSPSaga options
-------

local opts = { silent = true, noremap = true }
-- lsp provider to find the cursor word definition and reference
vim.api.nvim_set_keymap("n", "gh", "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>", opts)
-- code actions
vim.api.nvim_set_keymap("n", "<leader>ca", "<cmd>lua require('lspsaga.codeaction').code_action()<CR>", opts)
vim.api.nvim_set_keymap("v", "<leader>ca", ":<C-U>lua require('lspsaga.codeaction').range_code_action()<CR>", opts)
-- show hover doc
vim.api.nvim_set_keymap("n", "K", "<cmd>lua require('lspsaga.hover').render_hover_doc()<CR>", opts)
-- scroll down hover doc or scroll in definition preview
vim.api.nvim_set_keymap("n", "<C-f>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", opts)
-- scroll up hover doc
vim.api.nvim_set_keymap("n", "<C-b>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", opts)
-- signature help
vim.api.nvim_set_keymap("n", "gs", "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>", opts)
-- rename
vim.api.nvim_set_keymap("n", "gr", "<cmd>lua require('lspsaga.rename').rename()<CR>", opts)
-- preview definition
vim.api.nvim_set_keymap("n", "gD", "<cmd>lua require'lspsaga.provider'.preview_definition()<CR>", opts)
-- show
vim.api.nvim_set_keymap("n", "<leader>cd", "<cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>", opts)
-- only show diagnostic if cursor is over the area
vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>", opts)
-- jump diagnostic
vim.api.nvim_set_keymap("n", "[e", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>", opts)
vim.api.nvim_set_keymap("n", "]e", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>", opts)
vim.cmd([[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]])

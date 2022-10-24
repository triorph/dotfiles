require("lspsaga").init_lsp_saga()
local nvim_lsp = require("lspconfig")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

local lsp_format = function(bufnr)
	vim.lsp.buf.format({ bufnr = bufnr })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local group = vim.api.nvim_create_augroup("DocumentFormatting", { clear = true })
local on_attach = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			callback = function()
				lsp_format(bufnr)
			end,
			group = "DocumentFormatting",
			buffer = bufnr,
		})
	end
	vim.cmd([[autocmd CursorHold,CursorHoldI ]] .. bufnr .. [[  lua require'nvim-lightbulb'.update_lightbulb()]])

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	local function buf_nmap_cmd(keymap, command)
		local opts = { noremap = true, silent = true }
		buf_set_keymap("n", keymap, "<cmd>" .. command .. "<CR>", opts)
	end

	--Enable completion triggered by <c-x><c-o>
	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings.
	local opts = { noremap = true, silent = true }

	-- See `:help vim.lsp.*` for documentation on any of the below functions
	buf_nmap_cmd("gd", "Telescope lsp_definitions")
	buf_nmap_cmd("gR", "Telescope lsp_references")
	buf_nmap_cmd("gT", "Telescope lsp_type_definitions")
	buf_nmap_cmd("gi", "Telescope lsp_implementations")
	buf_nmap_cmd("gf", "lua vim.diagnostic.open_float()")
	buf_nmap_cmd("<C-k>", "lua vim.lsp.buf.signature_help()")
	buf_nmap_cmd("gr", "lua vim.lsp.buf.rename()")
	buf_nmap_cmd("<leader>tl", "lua vim.diagnostic.setloclist({open=false})<cr><cmd>Telescope loclist")
	buf_nmap_cmd("<leader>f", "lua vim.lsp.buf.format()")
	-- code actions
	buf_nmap_cmd("gx", "Lspsaga code_action")
	buf_set_keymap("x", "gx", ":<c-u>Lspsaga range_code_action<cr>", opts)
	-- show hover doc
	buf_nmap_cmd("K", "Lspsaga hover_doc")
	-- scroll down hover doc or scroll in definition preview
	buf_nmap_cmd("<C-f>", "lua require('lspsaga.action').smart_scroll_with_saga(1)")
	-- scroll up hover doc
	buf_nmap_cmd("<C-b>", "lua require('lspsaga.action').smart_scroll_with_saga(-1)")
	-- signature help
	buf_nmap_cmd("gs", "lua require('lspsaga.signaturehelp').signature_help()")
	-- show
	buf_nmap_cmd("go", "Lspsaga show_line_diagnostics")
	-- jump diagnostic
	buf_nmap_cmd("gj", "Lspsaga diagnostic_jump_next")
	buf_nmap_cmd("gk", "Lspsaga diagnostic_jump_prev")
end

local on_attach_no_format = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.document_range_formatting = false
	on_attach(client, bufnr)
end

-- vim.diagnostic.config({
-- 	virtual_text = false,
-- })

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "pyright", "solargraph" }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
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
	capabilities = capabilities,
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

nvim_lsp.yamlls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		yaml = {
			schemas = {
				["https://statlas.prod.atl-paas.net/dev/platform/json-schemas/micros-sd.schema.json"] = "*.sd.yml",
			},
		},
	},
})

nvim_lsp.rust_analyzer.setup({
	on_attach = on_attach,
	capabilities = capabilities,
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

local jdtls_on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	local function buf_nmap_cmd(keymap, command)
		local opts = { noremap = true, silent = true }
		buf_set_keymap("n", keymap, "<cmd>" .. command .. "<CR>", opts)
	end

	require("jdtls").setup_dap({ hotcodereplace = "auto" })
	buf_nmap_cmd("<leader>djm", "lua require('jdtls').test_nearest_method()")
	buf_nmap_cmd("<leader>djc", "lua require('jdtls').test_class()")
	on_attach(client, bufnr)
end

local jdtls_bundles = {
	vim.fn.glob(
		vim.env.HOME
			.. "/otherrepos/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar"
	),
}
vim.list_extend(
	jdtls_bundles,
	vim.split(vim.fn.glob(vim.env.HOME .. "/otherrepos/vscode-java-test/server/*.jar"), "\n")
)

local setup_jdtls = function()
	-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	local jdtls_base_path = "/opt/homebrew/Cellar/jdtls/1.15.0/libexec"

	local workspace_dir = "/Users/mwalsh2/work/" .. project_name
	local java_executable = "/Users/mwalsh2/.asdf/installs/java/openjdk-19/bin/java"
	local shared_config_path = jdtls_base_path .. "/config_mac"
	local jar_path = jdtls_base_path .. "/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar"
	local config = {
		-- The command that starts the language server
		-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
		cmd = {
			java_executable,
			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			"-Dosgi.bundles.defaultStartLevel=4",
			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			"-Dlog.level=ALL",
			"-noverify",
			"-Xms1G",
			"--add-modules=ALL-SYSTEM",
			"--add-opens",
			"java.base/java.util=ALL-UNNAMED",
			"--add-opens",
			"java.base/java.lang=ALL-UNNAMED",
			"-jar",
			jar_path,
			"-configuration",
			shared_config_path,
			"-data",
			workspace_dir,
		},

		-- This is the default if not provided, you can remove it. Or adjust as needed.
		-- One dedicated LSP server & client will be started per unique root_dir
		root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml" }),

		-- Here you can configure eclipse.jdt.ls specific settings
		-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
		-- for a list of options
		settings = {
			java = {
				-- format = {
				-- 	settings = {
				-- 		url = vim.env.HOME .. "/dotfiles/config/nvim/lua/config/eclipse-java-google-style.xml",
				-- 	},
				-- },
			},
		},

		-- Language server `initializationOptions`
		-- You need to extend the `bundles` with paths to jar files
		-- if you want to use additional eclipse.jdt.ls plugins.
		--
		-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
		--
		-- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
		init_options = {
			bundles = jdtls_bundles,
		},
		on_attach = jdtls_on_attach,
		capabilities = capabilities,
	}
	-- This starts a new client & server,
	-- or attaches to an existing client & server depending on the `root_dir`.
	require("jdtls").start_or_attach(config)
end

local jdtls_group = vim.api.nvim_create_augroup("jdtls", { clear = true })
vim.api.nvim_clear_autocmds({ group = jdtls_group })
vim.api.nvim_create_autocmd("FileType", { pattern = "java", callback = setup_jdtls, group = jdtls_group })

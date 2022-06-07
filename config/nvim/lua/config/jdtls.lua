local setup_jdtls = function()
	-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

	local workspace_dir = "/Users/mwalsh2/" .. project_name
	local config = {
		-- The command that starts the language server
		-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
		cmd = {
			"jdtls",
			workspace_dir,
		},

		-- This is the default if not provided, you can remove it. Or adjust as needed.
		-- One dedicated LSP server & client will be started per unique root_dir
		root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml" }),

		-- Here you can configure eclipse.jdt.ls specific settings
		-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
		-- for a list of options
		settings = {
			java = {},
		},

		-- Language server `initializationOptions`
		-- You need to extend the `bundles` with paths to jar files
		-- if you want to use additional eclipse.jdt.ls plugins.
		--
		-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
		--
		-- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
		init_options = {
			bundles = {},
		},
	}
	-- This starts a new client & server,
	-- or attaches to an existing client & server depending on the `root_dir`.
	require("jdtls").start_or_attach(config)
end

local group = vim.api.nvim_create_augroup("jdtls", { clear = true })
vim.api.nvim_clear_autocmds({ group = group })
vim.api.nvim_create_autocmd("FileType", { pattern="java", callback = setup_jdtls, group = group })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
-- to still try:
-- ahmedkhalf/project.nvim  (project management)
-- rmagatti/goto-preview  (popups of definition previews etc..)
-- RRethy/nvim-treesitter-textsubjects (expand your selection out or in via treesitter block)
-- princejoogie/dir-telescope.nvim (allow telescope to search on a directory before calling live_grep/find file)
-- folke/styler.nvim (different colorschemes per file type)
-- mrjones2014/legendary.nvim (define keymaps and sets up a command palette for them)
return require("lazy").setup({
	-- Packer can manage itself
	"wbthomason/packer.nvim", -- manage plugins

	-- git integration
	{
		"lewis6991/gitsigns.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup({ current_line_blame = true })
		end,
	},

	-- Language Server Processing(?)
	{ -- better LSP handling, and setup configs
		"glepnir/lspsaga.nvim",
		dependencies = { "neovim/nvim-lspconfig", "mfussenegger/nvim-jdtls", "simrat39/rust-tools.nvim" },
		config = function()
			require("config/lsp")
		end,
	},
	-- (additional support for rust-analyzer functions that aren't technically part of LSP spec)
	-- use({
	-- 	"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	-- 	config = function()
	-- 		require("lsp_lines").setup()
	-- 	end,
	-- })
	{ "rodjek/vim-puppet" },
	{ "kosayoda/nvim-lightbulb" }, -- puts lightbulbs when a code action is available
	{ -- takes care of showing LSP problems at the bottom of the screen
		"folke/trouble.nvim",
		dependencies = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/trouble")
		end,
	},

	-- Code formatting and linting via the LSP
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			require("config/format")
		end,
	},

	-- Tab headers
	{
		"akinsho/nvim-bufferline.lua",
		dependencies = "kyazdani42/nvim-web-devicons",
		version = "v2.*",
		config = function()
			require("config/bufferline")
		end,
	},

	-- statusline at the bottom of the screen
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons", lazy = true },
		config = function()
			require("config/lualine")
		end,
	},

	-- Fuzzy search/file find
	{ -- awesome plugin that lets you open a window to fuzzy-find things
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-lua/popup.nvim" },
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope-file-browser.nvim" },
			{ "nvim-telescope/telescope-ui-select.nvim" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = { border = {} },
				extensions = {
					file_browser = {
						theme = "ivy",
						hijack_netrw = true,
						mappings = {
							["i"] = {},
							["n"] = {},
						},
					},
				},
			})
			telescope.load_extension("neoclip")
			telescope.load_extension("mapper")
			telescope.load_extension("file_browser")
			-- telescope.load_extension("noice")
			telescope.load_extension("ui-select")
		end,
	},
	{ -- see your keymappings in telescope
		"lazytanuki/nvim-mapper",
		config = function()
			require("nvim-mapper").setup({})
		end,
	},
	-- Copy/Paste
	{ -- store all yanks and allow you to open up a history in telescope
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
		end,
	},

	-- Debugging
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("config/debug")
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup({})
		end,
	},

	-- Snippets
	{
		"L3MON4D3/LuaSnip",
		config = function()
			require("config/luasnip")
		end,
	},

	-- Autocompletion
	{ -- more of the "de facto" choice. Trying out.
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "onsails/lspkind.nvim" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help" },
			{ "hrsh7th/cmp-buffer" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "L3MON4D3/LuaSnip" },
		},
		config = function()
			require("config/cmp")
		end,
	},

	-- Better folds
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		config = function()
			vim.wo.foldcolumn = "1"
			vim.wo.foldlevel = 99 -- feel free to decrease the value
			vim.wo.foldenable = true

			require("ufo").setup()
		end,
	},

	-- Comments
	{ -- autocommenting of code
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- help
	{ -- after a pause, bring up a popup that shows what commands you have available after pressing a key
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	},
	{ "mrjones2014/legendary.nvim" },

	-- Highlight code
	{ -- treesitter - better highlighting of variables
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-context",
			"nvim-treesitter/playground",
		},
		build = function()
			vim.cmd([[:TSUpdate]])
		end,
		config = function()
			require("config/treesitter")
		end,
	},
	{ -- show indentation levels
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("config/indent")
		end,
	},
	{ "mechatroner/rainbow_csv" }, -- syntax highlighting of columns for CSV files

	-- Look pretty
	{ -- dashboard
		"goolord/alpha-nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("config/dashboard")
		end,
	},
	{ -- only show colour for what's active
		"folke/twilight.nvim",
		config = function()
			require("twilight").setup({
				context = 20, -- amount of lines we will try to show around the current line
				expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
					"function",
					"method",
				},
			})
		end,
	},
	{ -- F11 to go all in on focus
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode").setup({
				plugins = { tmux = { enabled = true } },
			})
		end,
	},
	{ -- fibonacci window splitting (doesn't interact well with bufferline though)
		"beauwilliams/focus.nvim",
		config = function()
			require("focus").setup()
		end,
	},

	-- colour schemes
	{
		"folke/tokyonight.nvim",
		dependencies = {
			{ "catppuccin/nvim", name = "catppuccin" },
			"EdenEast/nightfox.nvim",
			"morhetz/gruvbox",
			"rose-pine/neovim",
			"rockerBOO/boo-colorscheme-nvim",
			"shaunsingh/moonlight.nvim",
			"rebelot/kanagawa.nvim",
			"rktjmp/lush.nvim",
			"Scysta/pink-panic.nvim",
			{ "luisiacc/gruvbox-baby", branch = "main" },
			{ "nyoom-engineering/oxocarbon.nvim" },
		},

		config = function()
			require("config/colour")
		end,
	},
	-- Misc utils
	{ -- the ability to edit surrounding things, like quotes or brackets
		"kylechui/nvim-surround",
		version = "*",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{ -- git plugin
		"tpope/vim-fugitive",

		build = function()
			vim.cmd([[:helptags ~/.local/share/nvim/lazy/vim-fugitive/doc]])
		end,
	},
	{ "tpope/vim-sleuth" }, -- auto-detection of tabwidth etc..
	{ "wellle/targets.vim" }, -- more text objects, like "inside argument"
	{ --auto-close brackets etc..
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup()
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	}, -- auto-close html tags etc..
	{ -- stop windows jarring when opening stuff like Trouble etc..
		"luukvbaal/stabilize.nvim",
		config = function()
			require("stabilize").setup()
		end,
	},
	{ -- coloured borders on the active split
		"nvim-zh/colorful-winsep.nvim",
		config = function()
			require("colorful-winsep").setup({})
		end,
	},
	{ -- alternative to EasyMotion or Sneak for faster movement

		"ggandor/leap.nvim",
		dependencies = { "ggandor/flit.nvim" },
		config = function()
			require("leap").opts.safe_labels = {}
			require("leap").add_default_mappings()
			require("flit").setup({
				keys = { f = "f", F = "F", t = "t", T = "T" },
				labels_modes = "v",
				multiline = true,
				opts = {},
			})
			vim.keymap.set("n", "s", function()
				require("leap").leap({ target_windows = { vim.fn.win_getid() } })
			end, { noremap = true, silent = true })
		end,
	},
	{ "sindrets/diffview.nvim", dependencies = "nvim-lua/plenary.nvim" },
	{ -- allow . repeat to work with more plugins (surround, lightspeed, etc.)
		"tpope/vim-repeat",
		config = function()
			vim.cmd([[silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)]])
		end,
	},
	{
		"folke/noice.nvim",
		event = "VimEnter",
		config = function()
			require("noice").setup({
				messages = { enabled = false, view_search = false },
				lsp = {
					-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					inc_rename = false,
					lsp_doc_border = false,
				},
			})
		end,
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	{ -- disable repeatedly hjkl keys, to force you to get used to other options.
		"takac/vim-hardtime",
		config = function()
			vim.g.list_of_normal_keys = { "j", "k" }
			vim.g.list_of_visual_keys = {}
			vim.g.list_of_insert_keys = {}
			vim.g.hardtime_maxcount = 3
			vim.g.hardtime_default_on = 1
			vim.g.hardtime_motion_with_count_resets = 1
			vim.g.hardtime_ignore_buffer_patterns = { ".*lpha" }
		end,
	},
	{ "andymass/vim-matchup", event = "VimEnter" },
	{ "ThePrimeagen/vim-be-good" },
})

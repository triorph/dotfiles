local present, _ = pcall(require, "packerInit")
local packer

if present then
	packer = require("packer")
else
	return false
end
-- to still try:
-- ahmedkhalf/project.nvim  (project management)
-- rmagatti/goto-preview  (popups of definition previews etc..)
-- famiu/feline.nvim (alternative to lualine)
-- RRethy/nvim-treesitter-textsubjects (expand your selection out or in via treesitter block)
-- gelguy/wilder.nvim nice menu for ex-commands
-- simrat39/rust-tools.nvim (additional support for rust-analyzer functions that aren't technically part of LSP spec)
-- princejoogie/dir-telescope.nvim (allow telescope to search on a directory before calling live_grep/find file)
local use = packer.use
return packer.startup(function()
	-- Packer can manage itself
	use("wbthomason/packer.nvim") -- manage plugins

	-- git integration
	use({
		"lewis6991/gitsigns.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup({ current_line_blame = true })
		end,
	})

	-- Language Server Processing(?)
	use({ -- better LSP handling, and setup configs
		"glepnir/lspsaga.nvim",
		requires = { "neovim/nvim-lspconfig", "mfussenegger/nvim-jdtls" },
		config = function()
			require("config/lsp")
		end,
	})
	-- use({
	-- 	"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	-- 	config = function()
	-- 		require("lsp_lines").setup()
	-- 	end,
	-- })
	use({ "rodjek/vim-puppet" })
	use({ "kosayoda/nvim-lightbulb" }) -- puts lightbulbs when a code action is available
	use({ -- takes care of showing LSP problems at the bottom of the screen
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/trouble")
		end,
	})

	-- Code formatting and linting via the LSP
	use({
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			require("config/format")
		end,
	})

	-- Tab headers
	use({
		"akinsho/nvim-bufferline.lua",
		requires = "kyazdani42/nvim-web-devicons",
		tag = "v2.*",
		config = function()
			require("config/bufferline")
		end,
	})

	-- statusline at the bottom of the screen
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("config/lualine")
		end,
	})

	-- Fuzzy search/file find
	use({ -- awesome plugin that lets you open a window to fuzzy-find things
		"nvim-telescope/telescope.nvim",
		requires = {
			{ "nvim-lua/popup.nvim" },
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope-file-browser.nvim" },
		},
		config = function()
			require("telescope").setup({
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
			require("telescope").load_extension("neoclip")
			require("telescope").load_extension("mapper")
			require("telescope").load_extension("file_browser")
		end,
	})
	use({ -- see your keymappings in telescope
		"lazytanuki/nvim-mapper",
		config = function()
			require("nvim-mapper").setup({})
		end,
		before = "telescope.nvim",
	})
	-- Copy/Paste
	use({ -- store all yanks and allow you to open up a history in telescope
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
		end,
		before = "telescope.nvim",
	})

	-- Debugging
	use({
		"rcarriga/nvim-dap-ui",
		requires = { "mfussenegger/nvim-dap" },
		config = function()
			require("config/debug")
		end,
	})
	use({
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup({})
		end,
	})

	-- Snippets
	use({
		"L3MON4D3/LuaSnip",
		config = function()
			require("config/luasnip")
		end,
	})

	-- Autocompletion
	use({ -- more of the "de facto" choice. Trying out.
		"hrsh7th/nvim-cmp",
		requires = {
			{ "onsails/lspkind.nvim" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "L3MON4D3/LuaSnip" },
		},
		config = function()
			require("config/cmp")
		end,
	})

	-- Better folds
	use({
		"kevinhwang91/nvim-ufo",
		requires = "kevinhwang91/promise-async",
		config = function()
			vim.wo.foldcolumn = "1"
			vim.wo.foldlevel = 99 -- feel free to decrease the value
			vim.wo.foldenable = true

			require("ufo").setup()
		end,
	})

	-- Comments
	use({ -- autocommenting of code
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	-- help
	use({ -- after a pause, bring up a popup that shows what commands you have available after pressing a key
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	})

	-- Highlight code
	use({ -- treesitter - better highlighting of variables
		"nvim-treesitter/nvim-treesitter",
		requires = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-context",
			"nvim-treesitter/playground",
		},
		run = function()
			vim.cmd([[:TSUpdate]])
		end,
		config = function()
			require("config/treesitter")
		end,
	})
	use({ -- show indentation levels
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("config/indent")
		end,
	})
	use({ "mechatroner/rainbow_csv" }) -- syntax highlighting of columns for CSV files

	-- Look pretty
	use({ -- dashboard
		"goolord/alpha-nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("config/dashboard")
		end,
	})
	use({ -- only show colour for what's active
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
	})
	use({ -- F11 to go all in on focus
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode").setup({
				plugins = { tmux = { enabled = true } },
			})
		end,
	})
	use({ -- fibonacci window splitting (doesn't interact well with bufferline though)
		"beauwilliams/focus.nvim",
		config = function()
			require("focus").setup()
		end,
	})

	-- colour schemes
	use({
		"folke/tokyonight.nvim",
		requires = {
			{ "catppuccin/nvim", as = "catppuccin" },
			"EdenEast/nightfox.nvim",
			"morhetz/gruvbox",
			"rose-pine/neovim",
			"rockerBOO/boo-colorscheme-nvim",
			"shaunsingh/moonlight.nvim",
			"rebelot/kanagawa.nvim",
			"rktjmp/lush.nvim",
			"Scysta/pink-panic.nvim",
			{ "luisiacc/gruvbox-baby", branch = "main" },
			-- { "timilio/oxocarbon.nvim", branch = "fennel" },
		},

		config = function()
			require("config/colour")
		end,
	})
	-- Misc utils
	use({ "npxbr/glow.nvim", run = "GlowInstall" }) -- markdown preview
	use({ -- the ability to edit surrounding things, like quotes or brackets
		"kylechui/nvim-surround",
		tag = "*",
		config = function()
			require("nvim-surround").setup({})
		end,
	})
	use({ -- git plugin
		"tpope/vim-fugitive",

		run = function()
			vim.cmd([[:helptags ~/.local/share/nvim/site/pack/packer/start/vim-fugitive/doc]])
		end,
	})
	use({ "tpope/vim-sleuth" }) -- auto-detection of tabwidth etc..
	use({ "wellle/targets.vim" }) -- more text objects, like "inside argument"
	use({ "windwp/nvim-autopairs" }) --auto-close brackets etc..
	use({
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup()
		end,
	})
	use({
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	}) -- auto-close html tags etc..
	use({ -- stop windows jarring when opening stuff like Trouble etc..
		"luukvbaal/stabilize.nvim",
		config = function()
			require("stabilize").setup()
		end,
	})
	use({ -- coloured borders on the active split
		"nvim-zh/colorful-winsep.nvim",
		config = function()
			require("colorful-winsep").setup({})
		end,
	})
	use({ -- alternative to EasyMotion or Sneak for faster movement

		"ggandor/leap.nvim",
		requires = { "ggandor/flit.nvim" },
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
	})
	use({ "sindrets/diffview.nvim", requires = "nvim-lua/plenary.nvim" })
	use({ -- allow . repeat to work with more plugins (surround, lightspeed, etc.)
		"tpope/vim-repeat",
		config = function()
			vim.cmd([[silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)]])
		end,
	})
	-- use({
	-- 	"folke/noice.nvim",
	-- 	event = "VimEnter",
	-- 	config = function()
	-- 		require("noice").setup({ messages = { view_search = false } })
	-- 	end,
	-- 	requires = {
	-- 		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
	-- 		"MunifTanjim/nui.nvim",
	-- 		"rcarriga/nvim-notify",
	-- 		"hrsh7th/nvim-cmp",
	-- 	},
	-- })
	use({ -- disable repeatedly hjkl keys, to force you to get used to other options.
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
	})
	use({ "andymass/vim-matchup", event = "VimEnter" })
	use({ "ThePrimeagen/vim-be-good" })
end)

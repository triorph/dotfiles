local present, _ = pcall(require, "packerInit")
local packer

if present then
	packer = require("packer")
else
	return false
end

local use = packer.use
return packer.startup(function()
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"lewis6991/impatient.nvim",
		config = function()
			require("impatient").enable_profile()
		end,
	})
	-- git integration
	use({
		"tveskag/nvim-blame-line",
		config = function()
			vim.cmd([[autocmd BufEnter * EnableBlameLine]])
		end,
	})
	use({
		"lewis6991/gitsigns.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup()
		end,
	})

	-- Code formatting and linting
	use({ "neomake/neomake" })
	use({
		"lukas-reineke/format.nvim",
		config = function()
			require("config/format")
		end,
	})

	-- Language Server Processing(?)
	use({
		"glepnir/lspsaga.nvim",
		requires = { "neovim/nvim-lspconfig" },
		config = function()
			require("config/lsp")
		end,
	})
	use({ "kosayoda/nvim-lightbulb" })
	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/trouble")
		end,
	})

	-- Tab headers
	use({
		"akinsho/nvim-bufferline.lua",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/bufferline")
		end,
	})

	-- statusline at the bottom of the screen
	use({
		"hoob3rt/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("config/lualine")
		end,
	})

	-- Fuzzy search/file find
	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/popup.nvim" }, { "nvim-lua/plenary.nvim" } },
	})

	-- Autocompletion
	use({
		"ms-jpq/coq_nvim",
		branch = "coq",
		requires = { { "ms-jpq/coq.artifacts", branch = "artifacts" } },
		config = function()
			require("config/autocomplete")
		end,
	})

	-- Comments
	use("b3nj5m1n/kommentary")

	-- help
	use({
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	})

	-- Highlight code
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			vim.cmd([[:TSUpdate]])
		end,
		config = function()
			require("config/treesitter")
		end,
	})
	use({
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("config/indent")
		end,
	})
	use({ "mechatroner/rainbow_csv" })

	-- Look pretty
	use({
		"goolord/alpha-nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("config/dashboard")
		end,
	})
	use({
		"folke/twilight.nvim",
		config = function()
			require("twilight").setup({})
		end,
	})
	use({
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode").setup({
				plugins = { tmux = { enabled = true } },
			})
		end,
	})
	use({
		"beauwilliams/focus.nvim",
		config = function()
			require("focus").setup()
		end,
	})

	-- colour schemes
	use({
		"folke/tokyonight.nvim",
		config = function()
			require("config/colour")
		end,
	})
	use({ "EdenEast/nightfox.nvim" })
	use({ "Pocco81/Catppuccino.nvim" })
	use({ "morhetz/gruvbox" })

	-- Copy/Paste
	use({
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
			require("telescope").load_extension("neoclip")
		end,
	})

	-- Misc utils
	use({ "npxbr/glow.nvim", run = "GlowInstall" }) -- markdown preview
	use({ "tpope/vim-surround" }) -- the ability to edit surrounding things, like quotes or brackets
	use({ "wellle/targets.vim" }) -- more text objects, like "inside argument"
	use({ "ggandor/lightspeed.nvim" }) -- alternative to EasyMotion or Sneak for faster movement
	--[[ use({ -- disable repeatedly hjkl keys, to force you to get used to other options.
		"takac/vim-hardtime",
		config = function()
			vim.g.hardtime_default_on = 0
		end,
	}) ]]
	use({ "andymass/vim-matchup", event = "VimEnter" })
	use({ "ThePrimeagen/vim-be-good" })
end)

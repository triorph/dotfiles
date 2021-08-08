-- This file can be loaded by calling `lua require('plugins')` from your init.vim
vim.cmd([[packadd packer.nvim]])
packer = require("packer")
local use = packer.use
return require("packer").startup(function()
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

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
	use({ "anott03/nvim-lspinstall" })
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
		"hrsh7th/nvim-compe",
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

	-- Look pretty
	use({
		"glepnir/dashboard-nvim",
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
		"folke/tokyonight.nvim",
		config = function()
			require("config/colour")
		end,
	})

	-- Misc utils
	use({ "npxbr/glow.nvim", run = "GlowInstall" })
	use({ "windwp/nvim-autopairs" })
	use({ "tpope/vim-surround" })
	-- use({ "tpope/vim-endwise" })
	use({ "andymass/vim-matchup", event = "VimEnter" })
	use({ "ThePrimeagen/vim-be-good" })
end)

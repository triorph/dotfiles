-- This file can be loaded by calling `lua require('plugins')` from your init.vim
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function()
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"tveskag/nvim-blame-line",
		config = function()
			vim.cmd([[autocmd BufEnter * EnableBlameLine]])
		end,
	})

	use({ "neomake/neomake" })

	use({
		"glepnir/dashboard-nvim",
		config = function()
			require("config/dashboard")
		end,
	})

	use("b3nj5m1n/kommentary")

	use({
		"lukas-reineke/format.nvim",
		config = function()
			require("config/format")
		end,
	})

	use({ "kosayoda/nvim-lightbulb" })

	use({ "npxbr/glow.nvim", run = "GlowInstall" })

	use({ "anott03/nvim-lspinstall" })

	use({
		"akinsho/nvim-bufferline.lua",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/bufferline")
		end,
	})

	use({ "windwp/nvim-autopairs" })

	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/popup.nvim" }, { "nvim-lua/plenary.nvim" } },
	})

	use({
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})

	use({
		"hrsh7th/nvim-compe",
		config = function()
			require("config/autocomplete")
		end,
	})

	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("config/trouble")
		end,
	})

	use({
		"glepnir/lspsaga.nvim",
		requires = { "neovim/nvim-lspconfig" },
		config = function()
			require("config/lsp")
		end,
	})

	-- use({ "9mm/vim-closer" })
	-- use({ "tpope/vim-endwise" })
	-- use({ "andymass/vim-matchup", event = "VimEnter" })

	use({
		"lewis6991/gitsigns.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup()
		end,
	})

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

	use({
		"hoob3rt/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("config/lualine")
		end,
	})

	use({
		"folke/twilight.nvim",
		config = function()
			require("twilight").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})

	use({
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode").setup({
				plugins = { tmux = { enabled = true } },
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})

	use({
		"folke/tokyonight.nvim",
		config = function()
			require("config/colour")
		end,
	})

	use({ "ThePrimeagen/vim-be-good" })
end)

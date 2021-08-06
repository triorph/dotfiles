-- This file can be loaded by calling `lua require('plugins')` from your init.vim
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
	-- Packer can manage itself
	use 'wbthomason/packer.nvim'

	use {
		'glepnir/dashboard-nvim',
		config = function()
			require('config/dashboard')
end
	}

	-- using packer.nvim
	use {
		'lukas-reineke/format.nvim',
		config = function()
			require('config/format')
		end
	}
	use {'kosayoda/nvim-lightbulb'}
	use {'anott03/nvim-lspinstall'}
	use {
		'akinsho/nvim-bufferline.lua',
		requires = 'kyazdani42/nvim-web-devicons',
		config = function()
			require('config/bufferline')
		end
	}
	use {'windwp/nvim-autopairs'}
	use {
		'nvim-telescope/telescope.nvim',
		requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
	}
	use {
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup {
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			}
		end
	}
	use {
		"hrsh7th/nvim-compe",
		config = function()
			require('config/autocomplete')
		end
	}
	use {
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require('config/trouble')
		end
	}

	use {
		'glepnir/lspsaga.nvim',
		requires = {'neovim/nvim-lspconfig'},
		config = function()
			require('config/lsp')
		end
	}
	use {'9mm/vim-closer'}
	use {'tpope/vim-endwise'}

	-- Load on an autocommand event
	use {'andymass/vim-matchup', event = 'VimEnter'}

	-- Load on a combination of conditions: specific filetypes or commands
	-- Also run code after load (see the "config" key)
	use {
		'w0rp/ale',
		ft = {
			'sh',
			'zsh',
			'bash',
			'c',
			'cpp',
			'cmake',
			'html',
			'markdown',
			'racket',
			'vim',
			'tex'
		},
		cmd = 'ALEEnable',
		config = 'vim.cmd[[ALEEnable]]'
	}

	-- You can specify rocks in isolation
	use_rocks 'penlight'
	use_rocks {'lua-resty-http', 'lpeg'}

	-- Plugins can have post-install/update hooks
	use {
		'iamcco/markdown-preview.nvim',
		run = 'cd app && yarn install',
		cmd = 'MarkdownPreview'
	}

	-- Post-install/update hook with call of vimscript function with argument
	use {
		'glacambre/firenvim',
		run = function()
			vim.fn['firenvim#install'](0)
		end
	}

	-- Use dependency and run lua function after load
	use {
		'lewis6991/gitsigns.nvim',
		requires = {'nvim-lua/plenary.nvim'},
		config = function()
			require('gitsigns').setup()
		end
	}
	use {
		'nvim-treesitter/nvim-treesitter',
		run = function()
			vim.cmd [[:TSUpdate]]
		end,
		config = function()
			require('config/treesitter')
		end
	}
	use {
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require('config/indent')
		end
	}
	use {
		'hoob3rt/lualine.nvim',
		requires = {'kyazdani42/nvim-web-devicons', opt = true},
		config = function()
			require('config/lualine')
		end
	}

	-- You can alias plugin names
	use {
		'folke/tokyonight.nvim',
		config = function()
			require('config/colour')
		end
	}
end)


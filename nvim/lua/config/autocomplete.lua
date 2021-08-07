vim.o.completeopt = "menuone,noselect"
local opts = { silent = true, noremap = true }
require("compe").setup({
	enabled = true,
	autocomplete = true,
	debug = false,
	min_length = 1,
	preselect = "enable",
	throttle_time = 80,
	source_timeout = 200,
	resolve_timeout = 800,
	incomplete_delay = 400,
	max_abbr_width = 100,
	max_kind_width = 100,
	max_menu_width = 100,
	documentation = true,
	source = {
		path = true,
		buffer = true,
		calc = true,
		nvim_lsp = true,
		treesitter = true,
		nvim_lua = true,
		vsnip = true,
		ultisnips = true,
		luasnip = true,
	},
})
require("nvim-autopairs.completion.compe").setup({
	map_cr = true, --  map <CR> on insert mode
	map_complete = true, -- it will auto insert `(` after select function or method item
	auto_select = false, -- auto select first item
})

local npairs = require("nvim-autopairs")
local Rule = require("nvim-autopairs.rule")
npairs.setup({
	check_ts = true,
	disable_filetype = { "TelescopePrompt", "vim", "dashboard" },
	ts_config = {
		lua = { "string" }, -- it will not add pair on that treesitter node
		javascript = { "template_string" },
		java = false, -- don't check treesitter on java
	},
})

require("nvim-treesitter.configs").setup({
	autopairs = { enable = true },
})

local ts_conds = require("nvim-autopairs.ts-conds")
-- press % => %% is only inside comment or string
npairs.add_rules({
	Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({ "string", "comment" })),
	Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({ "function" })),
})

local expression_key_mapper = function(mode, key, expression)
	vim.api.nvim_set_keymap(mode, key, expression, { noremap = true, silent = true, expr = true })
end
expression_key_mapper("i", "<C-Space>", "compe#complete()")
expression_key_mapper("i", "<CR>", "compe#confirm('<CR>')")
expression_key_mapper("i", "<C-e>", "compe#close('<C-e>')")
expression_key_mapper("i", "<TAB>", 'pumvisible() ? "<C-n>" : "<TAB>"')
expression_key_mapper("i", "<S-TAB>", 'pumvisible() ? "<C-p>" : "<C-h>"')
expression_key_mapper("i", "<C-f>", "compe#scroll({ 'delta': +4 })")
expression_key_mapper("i", "<C-d>", "compe#scroll({ 'delta': -4 })")

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		{
			"bash",
			"c",
			"cpp",
			"dockerfile",
			"hcl",
			"html",
			"java",
			"javascript",
			"json",
			"jsonc",
			"lua",
			"python",
			"rust",
			"ruby",
			"typescript",
			"yaml",
			"regex",
			"markdown",
		},
	},
	ignore_install = {}, -- List of parsers to ignore installing
	indent = {
		enable = true,
	},
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = {}, -- list of language that will be disabled
		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
	textobjects = {
		select = {
			enable = true,

			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,

			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		lsp_interop = {
			enable = true,
			border = "none",
			peek_definition_code = {
				["<leader>df"] = "@function.outer",
				["<leader>dF"] = "@class.outer",
			},
		},
		playground = {
			enable = true,
			disable = {},
			updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
			persist_queries = false, -- Whether the query persists across vim sessions
			keybindings = {
				toggle_query_editor = "o",
				toggle_hl_groups = "i",
				toggle_injected_languages = "t",
				toggle_anonymous_nodes = "a",
				toggle_language_display = "I",
				focus_language = "f",
				unfocus_language = "F",
				update = "R",
				goto_node = "<cr>",
				show_help = "?",
			},
		},
	},
})

require("treesitter-context").setup({
	enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
	max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
	trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
	patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
		-- For all filetypes
		-- Note that setting an entry here replaces all other patterns for this entry.
		-- By setting the 'default' entry below, you can control which nodes you want to
		-- appear in the context window.
		default = {
			"class",
			"function",
			"method",
			-- 'for', -- These won't appear in the context
			-- 'while',
			-- 'if',
			-- 'switch',
			-- 'case',
		},
		-- Example for a specific filetype.
		-- If a pattern is missing, *open a PR* so everyone can benefit.
		--   rust = {
		--       'impl_item',
		--   },
	},
	exact_patterns = {
		-- Example for a specific filetype with Lua patterns
		-- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
		-- exactly match "impl_item" only)
		-- rust = true,
	},
})

-- Create a formatter for inline signalflow within terraform
-- Uses this video from TJ as a guide: https://www.youtube.com/watch?v=v3o9YaHBM4Q
--
-- looks for template_literal treesitter object under an attribute with identifier name "program_text"

local embedded_signalflow = vim.treesitter.parse_query(
	"hcl",
	[[
		(attribute
		  (identifier) @_name (#eq? @_name "program_text")
		  (expression 
			(template_expr 
			  (heredoc_template 
				(template_literal) @signalflow_text))))
	]]
)

local get_root = function(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "hcl", {})
	local tree = parser:parse()[1]
	return tree:root()
end

local Job = require("plenary.job")
local run_signalflow_formatter = function(input_text)
	local j = Job:new({
		command = "black",
		args = {
			"-",
		},
		writer = { input_text },
	})

	j:sync()
	local formatted = j:result()
	return formatted
end

local format_signalflow_in_terraform = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].filetype ~= "terraform" then
		vim.notify("can only be used in hcl (terraform) code")
		return
	end
	local root = get_root(bufnr)

	local changes = {}
	for id, node in embedded_signalflow:iter_captures(root, bufnr, 0, -1) do
		local name = embedded_signalflow.captures[id]
		if name == "signalflow_text" then
			local range = { node:range() }
			local indentation = string.rep(" ", range[2])

			-- run the formatter, based on the node text
			local formatted = run_signalflow_formatter(vim.treesitter.get_node_text(node, bufnr))

			for idx, line in ipairs(formatted) do
				formatted[idx] = indentation .. line
			end

			-- keep track of changes, in reverse order
			table.insert(changes, 1, {
				start = range[1],
				final = range[3] + 1,
				formatted = formatted,
			})
		end
	end
	for _, change in ipairs(changes) do
		vim.api.nvim_buf_set_lines(bufnr, change.start, change.final, false, change.formatted)
	end
end

vim.api.nvim_create_user_command("SignalFlowFormat", function()
	format_signalflow_in_terraform()
end, {})

-- Borrowed from TJ devries
local ls = require("luasnip")
local types = require("luasnip.util.types")

local snippet = ls.s
local f = ls.function_node
local c = ls.choice_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt

local same = function(index)
	return f(function(args)
		return args[1]
	end, { index })
end

ls.config.set_config({
	-- This tells LuaSnip to remember to keep around the last snippet.
	-- You can jump back into it even if you move outside of the selection
	history = true,

	-- This one is cool cause if you have dynamic snippets, it updates as you type!
	updateevents = "TextChanged,TextChangedI",

	-- Autosnippets:
	enable_autosnippets = true,

	-- Crazy highlights!!
	-- #vid3
	-- ext_opts = nil,
	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { " <- Current Choice", "NonTest" } },
			},
		},
	},
})

-- this will expand the current item or jump to the next item within the snippet.
vim.keymap.set({ "i", "s" }, "<c-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })

-- <c-j> is my jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

-- <c-l> is selecting within a list of options.
-- This is useful for choice nodes (introduced in the forthcoming episode 2)
vim.keymap.set("i", "<c-l>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end)

vim.keymap.set("i", "<c-u>", require("luasnip.extras.select_choice"))

-- shorcut to source my luasnips file again, which will reload my snippets
vim.keymap.set("n", "<leader>ss", "<cmd>source ~/.config/nvim/lua/config/luasnip.lua<CR>")

local rustsnips = {
	snippet("main", {
		t({ "fn main () " }),
		c(1, { t(""), t("-> Result<()> ") }),
		t({ "{", "    " }),
		i(0),
		t({ "", "}" }),
	}),

	snippet("modtest", {
		t({ "#[cfg(test)]", "mod test {", "    " }),
		c(1, { t("use super::*;"), t("") }),
		t({ "", "    " }),
		i(0),
		t({ "", "}" }),
	}),

	snippet("test", {
		t({ "#[test]", "fn " }),
		i(1, "testname"),
		t("() "),
		c(2, {
			t(""),
			t("-> Result<()> "),
		}),
		t({ "{", "    " }),
		i(0),
		t({ "", "}" }),
	}),

	snippet("eq", fmt("assert_eq!({}, {});{}", { i(1), i(2), i(0) })),

	snippet("enum", {
		t({ "#[derive(Debug, PartialEq)]", "enum " }),
		i(1, "Name"),
		t({ " {", "     " }),
		i(0),
		t({ "", "}" }),
	}),

	snippet("struct", {
		t({ "#[derive(Debug, PartialEq)]", "struct " }),
		i(1, "Name"),
		t({ " {", "    " }),
		i(0),
		t({ "", "}" }),
	}),

	snippet("pd", fmt([[println!("{}: {{:?}}", {});]], { same(1), i(1) })),
}
ls.add_snippets("all", rustsnips, { key = "miekrust" })

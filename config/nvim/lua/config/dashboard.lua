local alpha = require("alpha")
local theme = require("alpha.themes.startify")
theme.section.header.val = {
	[[                                   __                ]],
	[[      ___     ___    ___   __  __ /\_\    ___ ___    ]],
	[[     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
	[[    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
	[[    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
	[[     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
}
theme.section.header.opts.position = "center"
theme.section.top_buttons.val = {
	theme.button("e", " " .. " New file", ":ene <BAR> startinsert <CR>"),
}

-- disable MRU
theme.section.mru.val = { { type = "padding", val = 0 } }

-- retheme the mru_cwd
theme.section.mru_cwd.val = {
	{ type = "padding", val = 1 },
	{ type = "text", val = "Recently used files", opts = { hl = "SpecialComment" } },
	{ type = "padding", val = 1 },
	{
		type = "group",
		val = function()
			local ret = { theme.mru(0, vim.fn.getcwd(), 20) }
			vim.print(ret)
			for _, inner in ipairs(ret) do
				for _, val in ipairs(inner.val) do
					val.opts.position = "center"
				end
			end
			return ret
		end,
	},
}

theme.section.bottom_buttons.val = {
	theme.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
	theme.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
	theme.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
	theme.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
	theme.button("q", "  Quit NVIM", ":qa<CR>"),
}

-- Centrify all the items
for _, val in ipairs(theme.section.top_buttons.val) do
	val.opts.position = "center"
end
for _, val in ipairs(theme.section.mru_cwd.val) do
	val.opts = { position = "center" }
end
for _, val in ipairs(theme.section.bottom_buttons.val) do
	val.opts.position = "center"
end

alpha.setup(theme.opts)

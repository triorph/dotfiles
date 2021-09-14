local alpha = require("alpha")
local startify = require("alpha.themes.startify")
startify.section.header.val = {
	[[                                   __                ]],
	[[      ___     ___    ___   __  __ /\_\    ___ ___    ]],
	[[     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
	[[    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
	[[    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
	[[     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
}
startify.section.top_buttons.val = {
	startify.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
}
-- disable MRU
startify.section.mru.val = { { type = "padding", val = 0 } }

--
startify.section.mru_cwd.val = {
	{ type = "padding", val = 1 },
	{ type = "text", val = mru_title, opts = { hl = "SpecialComment" } },
	{ type = "padding", val = 1 },
	{
		type = "group",
		val = function()
			return { startify.mru(0, vim.fn.getcwd()) }
		end,
	},
}
--
startify.section.bottom_buttons.val = {
	startify.button("q", "  Quit NVIM", ":qa<CR>"),
}
startify.section.footer = {
	{ type = "text", val = "footer" },
}
-- startify.opts.layout = { position = "center" }
alpha.setup(startify.opts)

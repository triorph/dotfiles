hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()
hs.loadSpoon("Caffeine")
spoon.Caffeine:bindHotkeys({ toggle = { { "ctrl", "alt", "cmd" }, "c" } })
spoon.Caffeine:start()

local virtual_screens = require("virtual_screens")

local move_screen = function()
	print("Moving window")
	local window = hs.window.frontmostWindow()
	local next = virtual_screens.get_next_virtual_screen(window)
	virtual_screens.move_to_virtual_screen(window, next)
end

local embiggen_window = function(unit)
	print("Embiggening this window")
	local window = hs.window.frontmostWindow()
	if unit == nil then
		unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
	end
	virtual_screens.move_to_virtual_screen(window, nil, unit)
end

hs.hotkey.bind({ "ctrl", "alt" }, "m", move_screen)
hs.hotkey.bind({ "ctrl", "alt" }, "b", embiggen_window)

require("toggle_window")
require("newwp")
require("bluetooth")

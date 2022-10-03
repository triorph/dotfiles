hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

local move_screen = function()
	print("Moving window")
	local window = hs.window.frontmostWindow()
	local next = window:screen():next()
	window:moveToScreen(next)
end

local embiggen_window = function(unit)
	print("Embiggening this window")
	local window = hs.window.frontmostWindow()
	if unit == nil then
		unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
	end
	window:moveToUnit(unit)
end

hs.hotkey.bind({ "ctrl", "alt" }, "m", move_screen)
hs.hotkey.bind({ "ctrl", "alt" }, "b", embiggen_window)

require("toggle_window")
require("newwp")
require("bluetooth")

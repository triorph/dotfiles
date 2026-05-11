local debug_log = require("debug_log")
hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()
hs.loadSpoon("Caffeine")
spoon.Caffeine:bindHotkeys({ toggle = { { "ctrl", "alt", "cmd" }, "c" } })
spoon.Caffeine:start()

local virtual_screens = require("virtual_screens")

local frontmost_window = function()
	local window = hs.window.frontmostWindow()
	if window == nil then
		debug_log.log("No frontmost window")
	end
	return window
end

local move_screen = function()
	debug_log.log("Moving window")
	local window = frontmost_window()
	if window == nil then
		return
	end
	virtual_screens.move_to_next_leaf(window)
end

local embiggen_window = function(unit)
	debug_log.log("Embiggening this window")
	local window = frontmost_window()
	if window == nil then
		return
	end
	if unit == nil then
		virtual_screens.configure_window(window, { mode = "fixed" })
	else
		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = unit,
		})
	end
	virtual_screens.reapply_window(window)
end

local reapply_window = function()
	local window = frontmost_window()
	if window == nil then
		return
	end
	virtual_screens.reapply_window(window)
end

local increase_virtual_screens = function()
	virtual_screens.increase_virtual_screens()
	reapply_window()
end

local decrease_virtual_screens = function()
	virtual_screens.decrease_virtual_screens()
	reapply_window()
end

local toggle_floating = function()
	debug_log.log("Toggling floating mode")
	local window = frontmost_window()
	if window == nil then
		return
	end
	virtual_screens.toggle_floating(window)
	virtual_screens.reapply_window(window)
end

local increase_gap = function()
	virtual_screens.increase_gap()
	virtual_screens.reapply_all_windows()
end

local decrease_gap = function()
	virtual_screens.decrease_gap()
	virtual_screens.reapply_all_windows()
end

hs.hotkey.bind({ "ctrl", "alt" }, "m", move_screen)
hs.hotkey.bind({ "ctrl", "alt" }, "b", embiggen_window)
hs.hotkey.bind({ "ctrl", "alt" }, "f", toggle_floating)
hs.hotkey.bind({ "ctrl", "alt" }, "=", increase_virtual_screens)
hs.hotkey.bind({ "ctrl", "alt" }, "-", decrease_virtual_screens)
hs.hotkey.bind({ "ctrl", "alt" }, "]", increase_gap)
hs.hotkey.bind({ "ctrl", "alt" }, "[", decrease_gap)

require("toggle_window")
require("newwp")
require("bluetooth")
require("midi")

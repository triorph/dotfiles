local M = {}

local virtual_screen_multiplier = 2
function M.get_current_virtual_screen(window)
	hs.screen.allScreens()
	local real_screen_id = nil
	for i, v in pairs(hs.screen.allScreens()) do
		if v == window:screen() then
			real_screen_id = i
			break
		end
	end
	if real_screen_id == nil then
		print("Unable to find real screen for window. defaulting to 0")
		real_screen_id = 0
	end
	-- TODO: make virtual_screens configurable and not limited to x-only directions
	print(real_screen_id)
	print(window)
	print(window:topLeft())
	if
		virtual_screen_multiplier == 2
		and window:topLeft().x > hs.screen.allScreens()[real_screen_id]:currentMode().w / 2
	then
		return real_screen_id * virtual_screen_multiplier + 1
	else
		return real_screen_id * virtual_screen_multiplier
	end
end

function M.get_next_virtual_screen(window)
	local total_screens = #(hs.screen.allScreens())
	return (M.get_current_virtual_screen(window) + 1) % (total_screens * virtual_screen_multiplier)
end

function M.move_to_virtual_screen(window, virtual_screen, unit)
	if unit == nil then
		unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
	end
	if virtual_screen == nil then
		virtual_screen = M.get_current_virtual_screen(window)
	end
	print("Moving to virtual screen " .. virtual_screen)
	local real_screen = tonumber(virtual_screen / virtual_screen_multiplier)
	local screens_virtual = virtual_screen % virtual_screen_multiplier
	unit = { x = unit.x / 2 + 0.5 * screens_virtual, y = unit.y, w = unit.w / 2, h = unit.h }
	print(
		"Moving to real screen "
			.. real_screen
			.. " with virtual screen at "
			.. screens_virtual
			.. " giving us the location "
	)
	print(unit.x .. " " .. unit.y .. " " .. unit.w .. " " .. unit.h)
	window:moveToScreen(hs.screen.allScreens()[real_screen])
	window:moveToUnit(unit)
end

return M

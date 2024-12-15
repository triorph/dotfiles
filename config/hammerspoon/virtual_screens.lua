local M = {}

local virtual_screen_multiplier = { [0] = 1, [1] = 1 }
local virtual_screen_id_start = function(real_screen_id)
	local count = 0
	for i = 0, real_screen_id do
		if i < real_screen_id and virtual_screen_multiplier[i] ~= nil then
			count = count + virtual_screen_multiplier[i]
		end
	end
	return count
end

local deindex_virtual_screens = function(virtual_screen_id)
	print("Trying to de-index virtual screen " .. virtual_screen_id)
	local total_screens = #(hs.screen.allScreens())
	local total_virtual_screens = virtual_screen_id_start(total_screens + 1)
	for i = 0, total_virtual_screens do
		if virtual_screen_id < virtual_screen_multiplier[i] then
			print("Virtual screen de-indexed to screen " .. i .. " at virtual location " .. virtual_screen_id)
			return i, virtual_screen_id
		else
			virtual_screen_id = virtual_screen_id - virtual_screen_multiplier[i]
		end
	end
	print("Was unable to de-index virtual screen, so defaulting to 0,0")
	return 0, 0
end

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
		print("Unable to find real screen for window. defaulting to 1")
		real_screen_id = 1
	end
	local this_physical_screen = hs.screen.allScreens()[real_screen_id]
	real_screen_id = real_screen_id - 1 -- zero-index, which we will undo when moving
	-- TODO: make virtual_screens configurable and not limited to x-only directions
	print(real_screen_id)
	print(window)
	print(window:frame())
	print(this_physical_screen:absoluteToLocal(window:frame()))
	if
		virtual_screen_multiplier[real_screen_id] == 2
		and window:frame().x - this_physical_screen:frame().x > this_physical_screen:currentMode().w / 2
	then
		return virtual_screen_id_start(real_screen_id) + 1
	else
		return virtual_screen_id_start(real_screen_id)
	end
end

function M.get_next_virtual_screen(window)
	local total_screens = #(hs.screen.allScreens())
	local total_virtual_screens = virtual_screen_id_start(total_screens + 1)
	print(
		"We have "
			.. total_virtual_screens
			.. " virtual screens and our current virtual screen is "
			.. M.get_current_virtual_screen(window)
	)
	local ret = (M.get_current_virtual_screen(window) + 1) % total_virtual_screens
	print("So we are moving to screen " .. ret)
	return ret
end

function M.move_to_virtual_screen(window, virtual_screen, unit)
	if unit == nil then
		unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
	end
	if virtual_screen == nil then
		virtual_screen = M.get_current_virtual_screen(window)
	end
	print("Moving to virtual screen " .. virtual_screen)
	local real_screen, screens_virtual = deindex_virtual_screens(virtual_screen)
	-- local real_screen = tonumber(virtual_screen / virtual_screen_multiplier)
	-- local screens_virtual = virtual_screen % virtual_screen_multiplier
	unit = {
		x = unit.x / virtual_screen_multiplier[real_screen] + 0.5 * screens_virtual,
		y = unit.y,
		w = unit.w / virtual_screen_multiplier[real_screen],
		h = unit.h,
	}
	print(
		"Moving to real screen "
			.. real_screen
			.. " with virtual screen at "
			.. screens_virtual
			.. " giving us the location "
	)
	print(unit.x .. " " .. unit.y .. " " .. unit.w .. " " .. unit.h)
	window:moveToScreen(hs.screen.allScreens()[real_screen + 1]) -- remove zero index
	window:moveToUnit(unit)
end

return M

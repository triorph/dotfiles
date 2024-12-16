-- virtual screens are smaller subsections that divide up a main screen
--
-- I think I am inspiring myself too much by tiling windows here
-- and need to maintain all the use cases I want to consider:
--
-- use case 1:
--  I am on a giant mofo screen that is just too wide and doesn't really work
--  as a single screen, so  I want to do my usual thing with 2 sections being
--  treated as separate screens
--
--  use case 2:
--   I want to divide up the screen I am using in a spiral for tiling within it.
--
--  Other considerations:
--   Floating within the screen vs taking up the full section
--   Per window settings - floating in a larger space than others are bound to
--
--  Proposed solution:
--    - Each window has its screen possibilities and locations separately defined
--    - Each window can be floating or full-screen within those bounds, and
--    remembers which it is set to
--    - increasing the virtual screen count splits in half thecurrent virtual
--    screen for a windows
--    - we always split along the largest edge, so if halving a giant screen still
--    leaves a desktop sized area, furthre splits will half that same direction
--
--    still TODO for now
--

local M = {}

local virtual_screen_multiplier = { [0] = 1, [1] = 1 } --, [2] = 1, [3] = 1 }

local spirals = {
	[2] = {
		[0] = hs.geometry(0, 0, 0.5, 1.0),
		[1] = hs.geometry(0.5, 0, 0.5, 1.0),
	},
	[3] = {
		[0] = hs.geometry(0, 0, 0.5, 1.0),
		[1] = hs.geometry(0.5, 0, 0.5, 0.5),
		[2] = hs.geometry(0.5, 0.5, 0.5, 0.5),
	},
	[4] = {
		[0] = hs.geometry(0, 0, 0.5, 1.0),
		[1] = hs.geometry(0.5, 0, 0.5, 0.5),
		[2] = hs.geometry(0.75, 0.5, 0.25, 0.5),
		[3] = hs.geometry(0.5, 0.5, 0.25, 0.5),
	},
}

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
	local total_virtual_screens = virtual_screen_id_start(total_screens)
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

local get_screen_index_for_window = function(window)
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
	return real_screen_id
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local screen_id = get_screen_index_for_window(window) - 1
	print("Increasing virtual screens for screen " .. screen_id)
	virtual_screen_multiplier[screen_id] = virtual_screen_multiplier[screen_id] + 1
	print("New virtual screens are " .. virtual_screen_multiplier[screen_id])
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local screen_id = get_screen_index_for_window(window) - 1
	print("Decreasing virtual screens for screen " .. screen_id)
	local new_multiplier = virtual_screen_multiplier[screen_id] - 1
	if new_multiplier < 1 then
		new_multiplier = 1
	end
	print("New virtual screens are " .. new_multiplier)
	virtual_screen_multiplier[screen_id] = new_multiplier
end

function M.get_current_virtual_screen(window)
	local real_screen_id = get_screen_index_for_window(window)
	local this_physical_screen = hs.screen.allScreens()[real_screen_id]
	real_screen_id = real_screen_id - 1 -- zero-index, which we will undo when moving
	-- TODO: make virtual_screens configurable and not limited to x-only directions
	print(real_screen_id)
	print(window)
	print(window:frame())
	print(this_physical_screen:absoluteToLocal(window:frame()))
	local virtual_screen_id = 0
	for i = 0, 3 do
		local relative_x = (window:frame().x - this_physical_screen:frame().x) / this_physical_screen:frame().w
		local relative_y = (window:frame().y - this_physical_screen:frame().y) / this_physical_screen:frame().h
		local this_spirals = spirals[virtual_screen_multiplier[real_screen_id]]
		if this_spirals == nil then
			this_spirals = { [0] = hs.geometry(0, 0, 1, 1) }
		end
		print(relative_x .. " , " .. relative_y)
		if
			i < virtual_screen_multiplier[real_screen_id]
			and (
				relative_x >= this_spirals[i].x
				and relative_x < this_spirals[i].x + this_spirals[i].w
				and relative_y >= this_spirals[i].y
				and relative_y < this_spirals[i].y + this_spirals[i].h
			)
		then
			return virtual_screen_id_start(real_screen_id) + virtual_screen_id
		else
			virtual_screen_id = virtual_screen_id + 1
		end
	end
	print("No spirals matched")
	return virtual_screen_id_start(real_screen_id)
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
	if virtual_screen_multiplier[real_screen] > 1 then
		local this_spirals = spirals[virtual_screen_multiplier[real_screen]]
		unit = this_spirals[screens_virtual]
		local edge_size = 0.01
		unit = {
			x = unit.x + unit.w * edge_size,
			y = unit.y + unit.h * edge_size,
			h = unit.h * (1.0 - edge_size * 2),
			w = unit.w * (1.0 - edge_size * 2),
		}
	end
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

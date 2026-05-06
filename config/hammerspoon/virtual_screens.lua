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

local debug_enabled = true

local debug_log = function(...)
	if debug_enabled then
		print(...)
	end
end

M.set_debug = function(enabled)
	debug_enabled = enabled
end

-- The per_window_table has the following data structure
-- virtual_screens : a descriptor of which virtual screens exist for this window
-- floating size : how large the window is when in floating mode
-- position : a tuple of virtual screen, anchor type (floating vs fixed)

-- windows_table stores a per_window_table by window_id,
-- when a window_id does not exist in the dictionary, we should look up what the
-- per_window_table default is by the window name. This way, we can define
-- different per_window_table defaults for different window types
local default_window_table = {
	["default"] = {
		virtual_screens = { [0] = 1, [1] = 1 },
		floating_size = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		position = { 0, "floating" },
	},
}

local get_default_window_table = function(window_name)
	local ret = default_window_table["window_name"]
	if ret == nil then
		return default_window_table["default"]
	else
		return ret
	end
end

local default_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local virtual_screen_edge_size = 0.01
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

local fallback_spiral = { [0] = hs.geometry(0, 0, 1, 1) }

local virtual_screen_id_start = function(real_screen_id)
	local count = 0
	for i = 0, real_screen_id do
		if i < real_screen_id and virtual_screen_multiplier[i] ~= nil then
			count = count + virtual_screen_multiplier[i]
		end
	end
	return count
end

local get_spirals_for_screen = function(real_screen_id)
	local this_spirals = spirals[virtual_screen_multiplier[real_screen_id]]
	if this_spirals == nil then
		return fallback_spiral
	end
	return this_spirals
end

local apply_edge_padding = function(unit)
	return {
		x = unit.x + unit.w * virtual_screen_edge_size,
		y = unit.y + unit.h * virtual_screen_edge_size,
		h = unit.h * (1.0 - virtual_screen_edge_size * 2),
		w = unit.w * (1.0 - virtual_screen_edge_size * 2),
	}
end

local copy_unit = function(unit)
	return { x = unit.x, y = unit.y, w = unit.w, h = unit.h }
end

local relative_window_position = function(window, screen)
	return {
		x = (window:frame().x - screen:frame().x) / screen:frame().w,
		y = (window:frame().y - screen:frame().y) / screen:frame().h,
	}
end

local is_position_in_unit = function(position, unit)
	return position.x >= unit.x and position.x < unit.x + unit.w and position.y >= unit.y and position.y < unit.y + unit.h
end

local deindex_virtual_screens = function(virtual_screen_id)
	debug_log("Trying to de-index virtual screen " .. virtual_screen_id)
	local total_screens = #(hs.screen.allScreens())
	local total_virtual_screens = virtual_screen_id_start(total_screens)
	for i = 0, total_virtual_screens do
		if virtual_screen_id < virtual_screen_multiplier[i] then
			debug_log("Virtual screen de-indexed to screen " .. i .. " at virtual location " .. virtual_screen_id)
			return i, virtual_screen_id
		else
			virtual_screen_id = virtual_screen_id - virtual_screen_multiplier[i]
		end
	end
	debug_log("Was unable to de-index virtual screen, so defaulting to 0,0")
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
		debug_log("Unable to find real screen for window. defaulting to 1")
		real_screen_id = 1
	end
	return real_screen_id
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local screen_id = get_screen_index_for_window(window) - 1
	debug_log("Increasing virtual screens for screen " .. screen_id)
	virtual_screen_multiplier[screen_id] = virtual_screen_multiplier[screen_id] + 1
	debug_log("New virtual screens are " .. virtual_screen_multiplier[screen_id])
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local screen_id = get_screen_index_for_window(window) - 1
	debug_log("Decreasing virtual screens for screen " .. screen_id)
	local new_multiplier = virtual_screen_multiplier[screen_id] - 1
	if new_multiplier < 1 then
		new_multiplier = 1
	end
	debug_log("New virtual screens are " .. new_multiplier)
	virtual_screen_multiplier[screen_id] = new_multiplier
end

function M.get_current_virtual_screen(window)
	local real_screen_id = get_screen_index_for_window(window)
	local this_physical_screen = hs.screen.allScreens()[real_screen_id]
	real_screen_id = real_screen_id - 1 -- zero-index, which we will undo when moving
	-- TODO: make virtual_screens configurable and not limited to x-only directions
	debug_log(real_screen_id)
	debug_log(window)
	debug_log(window:frame())
	debug_log(this_physical_screen:absoluteToLocal(window:frame()))
	local virtual_screen_id = 0
	local position = relative_window_position(window, this_physical_screen)
	local this_spirals = get_spirals_for_screen(real_screen_id)
	for i = 0, 3 do
		debug_log(position.x .. " , " .. position.y)
		if i < virtual_screen_multiplier[real_screen_id] and is_position_in_unit(position, this_spirals[i]) then
			return virtual_screen_id_start(real_screen_id) + virtual_screen_id
		else
			virtual_screen_id = virtual_screen_id + 1
		end
	end
	debug_log("No spirals matched")
	return virtual_screen_id_start(real_screen_id)
end

function M.get_next_virtual_screen(window)
	local total_screens = #(hs.screen.allScreens())
	local total_virtual_screens = virtual_screen_id_start(total_screens + 1)
	debug_log(
		"We have "
			.. total_virtual_screens
			.. " virtual screens and our current virtual screen is "
			.. M.get_current_virtual_screen(window)
	)
	local ret = (M.get_current_virtual_screen(window) + 1) % total_virtual_screens
	debug_log("So we are moving to screen " .. ret)
	return ret
end

function M.move_to_virtual_screen(window, virtual_screen, unit)
	if unit == nil then
		unit = copy_unit(default_unit)
	end
	if virtual_screen == nil then
		virtual_screen = M.get_current_virtual_screen(window)
	end
	debug_log("Moving to virtual screen " .. virtual_screen)
	local real_screen, screens_virtual = deindex_virtual_screens(virtual_screen)
	if virtual_screen_multiplier[real_screen] > 1 then
		local this_spirals = get_spirals_for_screen(real_screen)
		unit = apply_edge_padding(this_spirals[screens_virtual])
	end
	debug_log(
		"Moving to real screen "
			.. real_screen
			.. " with virtual screen at "
			.. screens_virtual
			.. " giving us the location "
	)
	debug_log(unit.x .. " " .. unit.y .. " " .. unit.w .. " " .. unit.h)
	window:moveToScreen(hs.screen.allScreens()[real_screen + 1]) -- remove zero index
	window:moveToUnit(unit)
end

return M

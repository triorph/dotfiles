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
		virtual_screens = { [1] = 1, [2] = 1 },
		floating_size = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		position = { 1, "floating" },
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
local virtual_screen_multiplier = { [1] = 1, [2] = 1 } --, [3] = 1, [4] = 1 }

local spirals = {
	[2] = {
		[1] = hs.geometry(0, 0, 0.5, 1.0),
		[2] = hs.geometry(0.5, 0, 0.5, 1.0),
	},
	[3] = {
		[1] = hs.geometry(0, 0, 0.5, 1.0),
		[2] = hs.geometry(0.5, 0, 0.5, 0.5),
		[3] = hs.geometry(0.5, 0.5, 0.5, 0.5),
	},
	[4] = {
		[1] = hs.geometry(0, 0, 0.5, 1.0),
		[2] = hs.geometry(0.5, 0, 0.5, 0.5),
		[3] = hs.geometry(0.75, 0.5, 0.25, 0.5),
		[4] = hs.geometry(0.5, 0.5, 0.25, 0.5),
	},
}

local fallback_spiral = { [1] = hs.geometry(0, 0, 1, 1) }

local virtual_screen_count_before = function(physical_screen_index)
	local count = 0
	for i = 1, physical_screen_index - 1 do
		if virtual_screen_multiplier[i] ~= nil then
			count = count + virtual_screen_multiplier[i]
		end
	end
	return count
end

local virtual_screen_id_start = function(physical_screen_index)
	return virtual_screen_count_before(physical_screen_index) + 1
end

local total_virtual_screen_count = function()
	local total = 0
	local total_screens = #(hs.screen.allScreens())
	for physical_screen_index = 1, total_screens do
		if virtual_screen_multiplier[physical_screen_index] ~= nil then
			total = total + virtual_screen_multiplier[physical_screen_index]
		end
	end
	return total
end

local get_spirals_for_screen = function(physical_screen_index)
	local this_spirals = spirals[virtual_screen_multiplier[physical_screen_index]]
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
	local remaining_virtual_screens = virtual_screen_id
	local total_screens = #(hs.screen.allScreens())
	for physical_screen_index = 1, total_screens do
		local multiplier = virtual_screen_multiplier[physical_screen_index]
		if multiplier ~= nil and remaining_virtual_screens <= multiplier then
			debug_log(
				"Virtual screen de-indexed to physical screen index "
					.. physical_screen_index
					.. " at virtual index "
					.. remaining_virtual_screens
			)
			return physical_screen_index, remaining_virtual_screens
		elseif multiplier ~= nil then
			remaining_virtual_screens = remaining_virtual_screens - multiplier
		end
	end
	debug_log("Was unable to de-index virtual screen, so defaulting to 1,1")
	return 1, 1
end

local get_physical_screen_index_for_window = function(window)
	local physical_screen_index = nil
	for i, v in pairs(hs.screen.allScreens()) do
		if v == window:screen() then
			physical_screen_index = i
			break
		end
	end
	if physical_screen_index == nil then
		debug_log("Unable to find physical screen for window. defaulting to 1")
		physical_screen_index = 1
	end
	return physical_screen_index
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local physical_screen_index = get_physical_screen_index_for_window(window)
	debug_log("Increasing virtual screens for physical screen index " .. physical_screen_index)
	virtual_screen_multiplier[physical_screen_index] = virtual_screen_multiplier[physical_screen_index] + 1
	debug_log("New virtual screens are " .. virtual_screen_multiplier[physical_screen_index])
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local physical_screen_index = get_physical_screen_index_for_window(window)
	debug_log("Decreasing virtual screens for physical screen index " .. physical_screen_index)
	local new_multiplier = virtual_screen_multiplier[physical_screen_index] - 1
	if new_multiplier < 1 then
		new_multiplier = 1
	end
	debug_log("New virtual screens are " .. new_multiplier)
	virtual_screen_multiplier[physical_screen_index] = new_multiplier
end

function M.get_current_virtual_screen(window)
	local physical_screen_index = get_physical_screen_index_for_window(window)
	local physical_screen = hs.screen.allScreens()[physical_screen_index]
	-- TODO: make virtual_screens configurable and not limited to x-only directions
	debug_log(physical_screen_index)
	debug_log(window)
	debug_log(window:frame())
	debug_log(physical_screen:absoluteToLocal(window:frame()))
	local position = relative_window_position(window, physical_screen)
	local this_spirals = get_spirals_for_screen(physical_screen_index)
	for virtual_screen_index = 1, virtual_screen_multiplier[physical_screen_index] do
		debug_log(position.x .. " , " .. position.y)
		if is_position_in_unit(position, this_spirals[virtual_screen_index]) then
			return virtual_screen_id_start(physical_screen_index) + virtual_screen_index - 1
		end
	end
	debug_log("No spirals matched")
	return virtual_screen_id_start(physical_screen_index)
end

function M.get_next_virtual_screen(window)
	local total_virtual_screens = total_virtual_screen_count()
	debug_log(
		"We have "
			.. total_virtual_screens
			.. " virtual screens and our current virtual screen is "
			.. M.get_current_virtual_screen(window)
	)
	local ret = (M.get_current_virtual_screen(window) % total_virtual_screens) + 1
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
	local physical_screen_index, virtual_screen_index = deindex_virtual_screens(virtual_screen)
	if virtual_screen_multiplier[physical_screen_index] > 1 then
		local this_spirals = get_spirals_for_screen(physical_screen_index)
		unit = apply_edge_padding(this_spirals[virtual_screen_index])
	end
	debug_log(
		"Moving to physical screen index "
			.. physical_screen_index
			.. " with virtual screen index "
			.. virtual_screen_index
			.. " giving us the location "
	)
	debug_log(unit.x .. " " .. unit.y .. " " .. unit.w .. " " .. unit.h)
	window:moveToScreen(hs.screen.allScreens()[physical_screen_index])
	window:moveToUnit(unit)
end

return M

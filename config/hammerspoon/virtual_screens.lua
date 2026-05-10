-- virtual screens are smaller subsections that divide up a main screen
--
-- Public virtual screen IDs are 1-based, matching Lua/Hammerspoon table indexes.
-- Internally, each physical screen has a tree layout. Flat virtual screen IDs are
-- derived by flattening that tree's leaves.

local layout = require("virtual_screen_layout")

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
local screen_layouts = {}

local screen_size = function(screen)
	local frame = screen:frame()
	return { w = frame.w, h = frame.h }
end

local get_layout_for_screen = function(physical_screen_index)
	if screen_layouts[physical_screen_index] == nil then
		screen_layouts[physical_screen_index] = layout.new(screen_size(hs.screen.allScreens()[physical_screen_index]))
	end
	return screen_layouts[physical_screen_index]
end

local leaves_for_screen = function(physical_screen_index)
	return layout.leaves(get_layout_for_screen(physical_screen_index))
end

local virtual_screen_count_for_screen = function(physical_screen_index)
	return #leaves_for_screen(physical_screen_index)
end

local virtual_screen_count_before = function(physical_screen_index)
	local count = 0
	for i = 1, physical_screen_index - 1 do
		count = count + virtual_screen_count_for_screen(i)
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
		total = total + virtual_screen_count_for_screen(physical_screen_index)
	end
	return total
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

local leaf_for_window = function(window)
	local physical_screen_index = get_physical_screen_index_for_window(window)
	local physical_screen = hs.screen.allScreens()[physical_screen_index]
	local position = relative_window_position(window, physical_screen)
	local leaves = leaves_for_screen(physical_screen_index)

	for virtual_screen_index, leaf in ipairs(leaves) do
		if is_position_in_unit(position, leaf.rect) then
			return physical_screen_index, virtual_screen_index, leaf
		end
	end

	debug_log("No layout leaf matched; defaulting to first leaf")
	return physical_screen_index, 1, leaves[1]
end

local deindex_virtual_screens = function(virtual_screen_id)
	debug_log("Trying to de-index virtual screen " .. virtual_screen_id)
	local remaining_virtual_screens = virtual_screen_id
	local total_screens = #(hs.screen.allScreens())
	for physical_screen_index = 1, total_screens do
		local leaves = leaves_for_screen(physical_screen_index)
		if remaining_virtual_screens <= #leaves then
			debug_log(
				"Virtual screen de-indexed to physical screen index "
					.. physical_screen_index
					.. " at virtual index "
					.. remaining_virtual_screens
			)
			return physical_screen_index, remaining_virtual_screens, leaves[remaining_virtual_screens]
		end
		remaining_virtual_screens = remaining_virtual_screens - #leaves
	end
	debug_log("Was unable to de-index virtual screen, so defaulting to 1,1")
	local leaves = leaves_for_screen(1)
	return 1, 1, leaves[1]
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local physical_screen_index, _, leaf = leaf_for_window(window)
	debug_log("Increasing virtual screens for physical screen index " .. physical_screen_index)
	layout.split(get_layout_for_screen(physical_screen_index), leaf.path)
	debug_log("New virtual screens are " .. virtual_screen_count_for_screen(physical_screen_index))
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local physical_screen_index, _, leaf = leaf_for_window(window)
	debug_log("Decreasing virtual screens for physical screen index " .. physical_screen_index)
	layout.merge(get_layout_for_screen(physical_screen_index), leaf.path)
	debug_log("New virtual screens are " .. virtual_screen_count_for_screen(physical_screen_index))
end

function M.get_current_virtual_screen(window)
	local physical_screen_index, virtual_screen_index = leaf_for_window(window)
	return virtual_screen_id_start(physical_screen_index) + virtual_screen_index - 1
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
	local physical_screen_index, _, leaf = deindex_virtual_screens(virtual_screen)
	if virtual_screen_count_for_screen(physical_screen_index) > 1 then
		unit = apply_edge_padding(leaf.rect)
	end
	debug_log("Moving to physical screen index " .. physical_screen_index .. " giving us the location ")
	debug_log(unit.x .. " " .. unit.y .. " " .. unit.w .. " " .. unit.h)
	window:moveToScreen(hs.screen.allScreens()[physical_screen_index])
	window:moveToUnit(unit)
end

return M

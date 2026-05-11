-- Virtual screens are tree-based subsections of physical screens.
--
-- Public physical screen indexes and virtual screen IDs are 1-based, matching
-- Lua/Hammerspoon table indexes. Each physical screen owns a tree layout from
-- virtual_screen_layout.lua; flat virtual screen IDs are derived by traversing
-- the layout leaves in depth-first order.
--
-- Windows also have local occupancy state:
--   fixed: fill the current virtual screen, with padding when split
--   floating: apply a remembered unit inside the current virtual screen

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

local default_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local default_floating_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local virtual_screen_edge_size = 0.01
local screen_layouts = {}
local window_states = {}

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

local window_key = function(window)
	if window.id ~= nil then
		local ok, id = pcall(function()
			return window:id()
		end)
		if ok and id ~= nil then
			return id
		end
	end
	return tostring(window)
end

local get_window_state = function(window)
	local key = window_key(window)
	if window_states[key] == nil then
		window_states[key] = {
			mode = "fixed",
			floating_unit = copy_unit(default_floating_unit),
		}
	end
	return window_states[key]
end

local unit_within_region = function(region, unit)
	return {
		x = region.x + unit.x * region.w,
		y = region.y + unit.y * region.h,
		w = unit.w * region.w,
		h = unit.h * region.h,
	}
end

local unit_for_window_in_leaf = function(window, leaf, is_split)
	local state = get_window_state(window)
	if state.mode == "floating" then
		return unit_within_region(leaf.rect, state.floating_unit)
	end
	if is_split then
		return apply_edge_padding(leaf.rect)
	end
	return copy_unit(default_unit)
end

function M.configure_window(window, config)
	local state = get_window_state(window)
	if config.mode ~= nil then
		state.mode = config.mode
	end
	if config.floating_unit ~= nil then
		state.floating_unit = copy_unit(config.floating_unit)
	end
end

function M.toggle_floating(window)
	local state = get_window_state(window)
	if state.mode == "floating" then
		state.mode = "fixed"
	else
		state.mode = "floating"
	end
	return state.mode
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
	if unit ~= nil then
		M.configure_window(window, {
			mode = "floating",
			floating_unit = unit,
		})
	end
	if virtual_screen == nil then
		virtual_screen = M.get_current_virtual_screen(window)
	end
	debug_log("Moving to virtual screen " .. virtual_screen)
	local physical_screen_index, _, leaf = deindex_virtual_screens(virtual_screen)
	local target_unit = unit_for_window_in_leaf(window, leaf, virtual_screen_count_for_screen(physical_screen_index) > 1)
	debug_log("Moving to physical screen index " .. physical_screen_index .. " giving us the location ")
	debug_log(target_unit.x .. " " .. target_unit.y .. " " .. target_unit.w .. " " .. target_unit.h)
	window:moveToScreen(hs.screen.allScreens()[physical_screen_index])
	window:moveToUnit(target_unit)
end

return M

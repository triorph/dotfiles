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

local debug_log = require("debug_log")
local layout = require("virtual_screen_layout")

local M = {}

local default_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local default_floating_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local virtual_screen_gap = 0.02
local virtual_screen_gap_step = 0.005

M.set_debug = function(enabled)
	debug_log.set_enabled(enabled)
end

local log_gap = function()
	debug_log.log("Virtual screen gap is now " .. virtual_screen_gap)
end

function M.increase_gap()
	virtual_screen_gap = virtual_screen_gap + virtual_screen_gap_step
	log_gap()
	return virtual_screen_gap
end

function M.decrease_gap()
	virtual_screen_gap = virtual_screen_gap - virtual_screen_gap_step
	if virtual_screen_gap < 0 then
		virtual_screen_gap = 0
	end
	log_gap()
	return virtual_screen_gap
end

function M.get_gap()
	return virtual_screen_gap
end
local window_states = {}
local get_window_state
local get_physical_screen_index_for_window

local screen_size = function(screen)
	local frame = screen:frame()
	return { w = frame.w, h = frame.h }
end

local leaves_for_window_on_screen = function(window, physical_screen_index)
	return layout.leaves(get_window_state(window).layout, screen_size(hs.screen.allScreens()[physical_screen_index]))
end

local virtual_screen_count_for_window = function(window)
	return #leaves_for_window_on_screen(window, get_physical_screen_index_for_window(window))
end

local total_virtual_screen_count = function(window)
	return virtual_screen_count_for_window(window) * #(hs.screen.allScreens())
end

local virtual_screen_id_for = function(window, physical_screen_index, virtual_screen_index)
	local leaf_count = virtual_screen_count_for_window(window)
	return ((physical_screen_index - 1) * leaf_count) + virtual_screen_index
end

local apply_edge_padding = function(unit)
	return {
		x = unit.x + unit.w * virtual_screen_gap,
		y = unit.y + unit.h * virtual_screen_gap,
		h = unit.h * (1.0 - virtual_screen_gap * 2),
		w = unit.w * (1.0 - virtual_screen_gap * 2),
	}
end

local copy_unit = function(unit)
	return { x = unit.x, y = unit.y, w = unit.w, h = unit.h }
end

local copy_path = function(path)
	local copied = {}
	for i, value in ipairs(path or {}) do
		copied[i] = value
	end
	return copied
end

local paths_equal = function(left, right)
	if #left ~= #right then
		return false
	end
	for i, value in ipairs(left) do
		if right[i] ~= value then
			return false
		end
	end
	return true
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

function M.has_window_state(window)
	return window_states[window_key(window)] ~= nil
end

get_window_state = function(window)
	local key = window_key(window)
	if window_states[key] == nil then
		window_states[key] = {
			physical_screen_index = get_physical_screen_index_for_window(window),
			layout = layout.new(),
			current_path = {},
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

local unit_for_window_in_leaf = function(window, leaf)
	local state = get_window_state(window)
	if state.mode == "floating" then
		return unit_within_region(leaf.rect, state.floating_unit)
	end
	return apply_edge_padding(leaf.rect)
end

local leaf_index_for_path = function(leaves, path)
	for index, leaf in ipairs(leaves) do
		if paths_equal(leaf.path, path) then
			return index, leaf
		end
	end
	return 1, leaves[1]
end

local ensure_path_exists = function(state, path)
	local parent = {}
	for _, side in ipairs(path or {}) do
		layout.split(state.layout, parent)
		parent[#parent + 1] = side
	end
end

function M.configure_window(window, config)
	local state = get_window_state(window)
	if config.mode ~= nil then
		state.mode = config.mode
	end
	if config.floating_unit ~= nil then
		state.floating_unit = copy_unit(config.floating_unit)
	end
	if config.default_path ~= nil then
		ensure_path_exists(state, config.default_path)
		state.current_path = copy_path(config.default_path)
		state.physical_screen_index = get_physical_screen_index_for_window(window)
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

get_physical_screen_index_for_window = function(window)
	local physical_screen_index = nil
	for i, v in pairs(hs.screen.allScreens()) do
		if v == window:screen() then
			physical_screen_index = i
			break
		end
	end
	if physical_screen_index == nil then
		debug_log.log("Unable to find physical screen for window. defaulting to 1")
		physical_screen_index = 1
	end
	return physical_screen_index
end

local leaf_for_window = function(window)
	local state = get_window_state(window)
	local physical_screen_index = state.physical_screen_index or get_physical_screen_index_for_window(window)
	local leaves = leaves_for_window_on_screen(window, physical_screen_index)
	local virtual_screen_index, leaf = leaf_index_for_path(leaves, state.current_path or {})
	return physical_screen_index, virtual_screen_index, leaf
end

local deindex_virtual_screens = function(window, virtual_screen_id)
	debug_log.log("Trying to de-index virtual screen " .. virtual_screen_id)
	local leaf_count = virtual_screen_count_for_window(window)
	local physical_screen_index = math.floor((virtual_screen_id - 1) / leaf_count) + 1
	local virtual_screen_index = ((virtual_screen_id - 1) % leaf_count) + 1
	local leaves = leaves_for_window_on_screen(window, physical_screen_index)
	if physical_screen_index <= #(hs.screen.allScreens()) and leaves[virtual_screen_index] ~= nil then
		debug_log.log(
			"Virtual screen de-indexed to physical screen index "
				.. physical_screen_index
				.. " at virtual index "
				.. virtual_screen_index
		)
		return physical_screen_index, virtual_screen_index, leaves[virtual_screen_index]
	end
	debug_log.log("Was unable to de-index virtual screen, so defaulting to 1,1")
	local fallback_leaves = leaves_for_window_on_screen(window, 1)
	return 1, 1, fallback_leaves[1]
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local state = get_window_state(window)
	local physical_screen_index, _, leaf = leaf_for_window(window)
	debug_log.log("Increasing virtual screens for physical screen index " .. physical_screen_index)
	layout.split(state.layout, leaf.path)
	state.current_path = copy_path(leaf.path)
	debug_log.log("New virtual screens are " .. virtual_screen_count_for_window(window))
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	local state = get_window_state(window)
	local physical_screen_index, _, leaf = leaf_for_window(window)
	debug_log.log("Decreasing virtual screens for physical screen index " .. physical_screen_index)
	layout.merge(state.layout, leaf.path)
	local resolved = layout.resolve(state.layout, leaf.path, screen_size(hs.screen.allScreens()[physical_screen_index]))
	state.current_path = resolved and copy_path(resolved.path) or {}
	debug_log.log("New virtual screens are " .. virtual_screen_count_for_window(window))
end

function M.get_current_virtual_screen(window)
	local physical_screen_index, virtual_screen_index = leaf_for_window(window)
	return virtual_screen_id_for(window, physical_screen_index, virtual_screen_index)
end

function M.get_next_virtual_screen(window)
	local total_virtual_screens = total_virtual_screen_count(window)
	debug_log.log(
		"We have "
			.. total_virtual_screens
			.. " virtual screens and our current virtual screen is "
			.. M.get_current_virtual_screen(window)
	)
	local ret = (M.get_current_virtual_screen(window) % total_virtual_screens) + 1
	debug_log.log("So we are moving to screen " .. ret)
	return ret
end

function M.move_to_virtual_screen(window, virtual_screen, unit)
	if unit ~= nil then
		M.configure_window(window, {
			mode = "floating",
			floating_unit = unit,
		})
	end

	local state = get_window_state(window)
	local physical_screen_index, leaf
	if virtual_screen ~= nil then
		debug_log.log("Moving to virtual screen " .. virtual_screen)
		local virtual_screen_index
		physical_screen_index, virtual_screen_index, leaf = deindex_virtual_screens(window, virtual_screen)
		state.physical_screen_index = physical_screen_index
		state.current_path = copy_path(leaf.path)
	else
		physical_screen_index, _, leaf = leaf_for_window(window)
	end

	local target_unit = unit_for_window_in_leaf(window, leaf)
	debug_log.log("Moving to physical screen index " .. physical_screen_index .. " giving us the location ")
	debug_log.log(target_unit.x .. " " .. target_unit.y .. " " .. target_unit.w .. " " .. target_unit.h)
	window:moveToScreen(hs.screen.allScreens()[physical_screen_index])
	window:moveToUnit(target_unit)
end

function M.reapply_window_layout(window)
	M.move_to_virtual_screen(window)
end

function M.move_to_next_virtual_screen(window)
	M.move_to_virtual_screen(window, M.get_next_virtual_screen(window))
end

return M

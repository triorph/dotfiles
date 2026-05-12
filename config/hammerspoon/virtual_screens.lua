-- Virtual screens are path-based subsections of physical screens.
--
-- Each managed window stores:
--   physical_screen_index: current target monitor
--   current_path: binary split path within that monitor, e.g. { 1, 2 }
--   mode/floating_unit: how to occupy the selected path rectangle
--
-- No possible split tree is stored. The set of possible leaves is inferred from
-- current_path depth. For example { 1, 2 } means all depth-2 paths are possible:
-- {1,1}, {1,2}, {2,1}, {2,2}.

local layout = require("virtual_screen_layout")
local debug_log = require("debug_log")

local M = {}

local default_floating_unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
local virtual_screen_gap = 0.02
local virtual_screen_gap_step = 0.005
local window_states = {}

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

local screen_size = function(screen)
	local frame = screen:frame()
	return { w = frame.w, h = frame.h }
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

local window_key = function(window)
	return window:id()
end

local has_window = function(window)
	if window == nil then
		debug_log.log("No window provided")
		return false
	end
	return true
end

local get_physical_screen_index_for_window = function(window)
	local this_screen = window:screen()
	for physical_screen_index, screen in ipairs(hs.screen.allScreens()) do
		if screen == this_screen then
			return physical_screen_index
		end
	end
	return 1
end

local floating_unit_for_current_frame = function(window)
	local screen = window:screen()
	local screen_frame = screen:frame()
	local frame = window:frame()
	return {
		x = (frame.x - screen_frame.x) / screen_frame.w,
		y = (frame.y - screen_frame.y) / screen_frame.h,
		w = frame.w / screen_frame.w,
		h = frame.h / screen_frame.h,
	}
end

function M.has_window_state(window)
	return has_window(window) and window_states[window_key(window)] ~= nil
end

local get_window_state = function(window, adopt_current_frame)
	local key = window_key(window)
	if window_states[key] == nil then
		window_states[key] = {
			window = window,
			physical_screen_index = get_physical_screen_index_for_window(window),
			current_path = {},
			mode = adopt_current_frame and "floating" or "fixed",
			floating_unit = adopt_current_frame and floating_unit_for_current_frame(window) or copy_unit(default_floating_unit),
		}
	end
	window_states[key].window = window
	return window_states[key]
end

local unit_within_region = function(region, unit)
	return {
		x = region.x + region.w * unit.x,
		y = region.y + region.h * unit.y,
		w = region.w * unit.w,
		h = region.h * unit.h,
	}
end

local unit_for_window_in_rect = function(window, rect)
	local state = get_window_state(window)
	if state.mode == "floating" then
		return unit_within_region(rect, state.floating_unit)
	end
	return apply_edge_padding(rect)
end

local path_rect = function(path, physical_screen_index)
	return layout.rect_for_path(path, screen_size(hs.screen.allScreens()[physical_screen_index]))
end

local apply_window_location = function(window, physical_screen_index, path)
	local target_unit = unit_for_window_in_rect(window, path_rect(path, physical_screen_index))
	debug_log.log("Moving to physical screen index " .. physical_screen_index .. " giving us the location ")
	debug_log.log(target_unit.x .. " " .. target_unit.y .. " " .. target_unit.w .. " " .. target_unit.h)
	window:moveToScreen(hs.screen.allScreens()[physical_screen_index])
	window:moveToUnit(target_unit)
end

function M.configure_window(window, config)
	if not has_window(window) then
		return
	end
	config = config or {}
	local state = get_window_state(window)
	if config.mode ~= nil then
		state.mode = config.mode
	end
	if config.floating_unit ~= nil then
		state.floating_unit = copy_unit(config.floating_unit)
	end
	if config.default_path ~= nil then
		state.current_path = copy_path(config.default_path)
		state.physical_screen_index = get_physical_screen_index_for_window(window)
	end
end

function M.toggle_floating(window)
	if not has_window(window) then
		return
	end
	local state = get_window_state(window)
	if state.mode == "floating" then
		state.mode = "fixed"
	else
		state.mode = "floating"
	end
end

M.increase_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	if not has_window(window) then
		return
	end
	local state = get_window_state(window)
	state.current_path[#state.current_path + 1] = 1
	state.physical_screen_index = state.physical_screen_index or get_physical_screen_index_for_window(window)
	debug_log.log("Increased virtual screen depth to " .. #state.current_path)
end

M.decrease_virtual_screens = function()
	local window = hs.window.frontmostWindow()
	if not has_window(window) then
		return
	end
	local state = get_window_state(window)
	state.current_path = layout.decrease_path(state.current_path)
	state.physical_screen_index = state.physical_screen_index or get_physical_screen_index_for_window(window)
	debug_log.log("Decreased virtual screen depth to " .. #state.current_path)
end

local next_location_for_window = function(window, adopt_current_frame)
	local state = get_window_state(window, adopt_current_frame)
	local next_path = layout.next_path(state.current_path)
	if next_path ~= nil then
		return state.physical_screen_index, next_path
	end

	local screen_count = #(hs.screen.allScreens())
	local next_physical_screen_index = (state.physical_screen_index % screen_count) + 1
	return next_physical_screen_index, layout.first_path(layout.depth_for_path(state.current_path))
end

function M.move_to_path(window, path, physical_screen_index)
	if not has_window(window) then
		return
	end
	local state = get_window_state(window)
	state.physical_screen_index = physical_screen_index or state.physical_screen_index or get_physical_screen_index_for_window(window)
	state.current_path = copy_path(path or state.current_path or {})
	apply_window_location(window, state.physical_screen_index, state.current_path)
end

function M.reapply_window(window)
	if not has_window(window) then
		return
	end
	local state = get_window_state(window)
	M.move_to_path(window, state.current_path, state.physical_screen_index)
end

function M.get_physical_screen_for_window(window)
	if window == nil then
		debug_log.log("No window provided")
		return nil
	end
	local state = window_states[window_key(window)]
	if state ~= nil and state.physical_screen_index ~= nil then
		return hs.screen.allScreens()[state.physical_screen_index]
	end
	return window:screen()
end

function M.reapply_all_windows()
	for _, state in pairs(window_states) do
		if state.window ~= nil then
			M.reapply_window(state.window)
		end
	end
end

function M.move_to_next_leaf(window)
	if not has_window(window) then
		return
	end
	local physical_screen_index, path = next_location_for_window(window, not M.has_window_state(window))
	local state = get_window_state(window)
	state.physical_screen_index = physical_screen_index
	state.current_path = copy_path(path)
	apply_window_location(window, physical_screen_index, path)
end

return M

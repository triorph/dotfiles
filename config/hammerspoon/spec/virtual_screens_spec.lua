local function assert_unit(actual, expected)
	local epsilon = 0.000001
	for _, key in ipairs({ "x", "y", "w", "h" }) do
		assert.is_true(
			math.abs(actual[key] - expected[key]) < epsilon,
			"expected " .. key .. "=" .. expected[key] .. ", got " .. tostring(actual[key])
		)
	end
end

local function make_screen(id, frame)
	local screen = { id = id, _frame = frame }

	function screen:frame()
		return self._frame
	end

	function screen:absoluteToLocal(rect)
		return {
			x = (rect.x - self._frame.x) / self._frame.w,
			y = (rect.y - self._frame.y) / self._frame.h,
		}
	end

	return screen
end

local function make_window(screen, frame)
	local window = {
		_screen = screen,
		_frame = frame,
		_id = tostring({}),
	}

	function window:id()
		return self._id
	end

	function window:screen()
		return self._screen
	end

	function window:frame()
		return self._frame
	end

	function window:setFrame(frame)
		self._frame = frame
	end

	function window:moveToScreen(next_screen)
		self.moved_to_screen = next_screen
		self._screen = next_screen
	end

	function window:moveToUnit(unit)
		self.moved_to_unit = unit
	end

	return window
end

describe("virtual_screens", function()
	local screens
	local frontmost_window
	local virtual_screens
	local debug_log

	before_each(function()
		screens = {
			make_screen("primary", { x = 0, y = 0, w = 1000, h = 1000 }),
		}
		frontmost_window = nil

		_G.hs = {
			geometry = function(x, y, w, h)
				return { x = x, y = y, w = w, h = h }
			end,
			screen = {
				allScreens = function()
					return screens
				end,
			},
			window = {
				frontmostWindow = function()
					return frontmost_window
				end,
			},
		}

		package.loaded["debug_log"] = nil
		debug_log = require("debug_log")
		debug_log.set_enabled(false)
		package.loaded["virtual_screen_layout"] = nil
		package.loaded["virtual_screens"] = nil
		virtual_screens = require("virtual_screens")
		virtual_screens.set_debug(false)
	end)

	it("adopts an unmanaged window as floating from its current frame before moving to the next location", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 200, w = 300, h = 400 })

		virtual_screens.move_to_next_leaf(window)

		assert.are.equal(screens[2], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.1, y = 0.2, w = 0.3, h = 0.4 })
	end)

	it("applies the configured gap to fixed windows on an unsplit screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, { mode = "fixed" })
		virtual_screens.reapply_window(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.02, y = 0.02, w = 0.96, h = 0.96 })
	end)

	it("applies default path placement for newly configured fixed windows", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, { mode = "fixed", default_path = { 1 } })
		virtual_screens.reapply_window(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("creates parent splits implied by a deeper default path", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, { mode = "fixed", default_path = { 1, 2 } })
		virtual_screens.reapply_window(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.51, w = 0.48, h = 0.48 })
	end)

	it("moves directly to a path for tests and explicit placement", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_path(window, { 2, 1 })

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.01, w = 0.48, h = 0.48 })
	end)

	it("moves to a path on a specific physical screen", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_path(window, { 1 }, 2)

		assert.are.equal(screens[2], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("splits the frontmost window's current path", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 1 })
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_path(window, { 1, 1 })
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.01, w = 0.48, h = 0.48 })
		virtual_screens.move_to_path(window, { 1, 2 })
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.51, w = 0.48, h = 0.48 })
	end)

	it("decreases by merging the current path back to its parent", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 1, 2 })

		virtual_screens.decrease_virtual_screens()
		virtual_screens.reapply_window(window)

		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("keeps virtual split trees independent per window", function()
		local slack = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		local kitty = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = slack

		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(slack, { 2 })
		assert_unit(slack.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })

		virtual_screens.configure_window(kitty, { mode = "fixed" })
		virtual_screens.reapply_window(kitty)
		assert_unit(kitty.moved_to_unit, { x = 0.02, y = 0.02, w = 0.96, h = 0.96 })
	end)

	it("traverses a deeper split tree in fixed-depth DFS order within one physical screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 1, 1 })

		virtual_screens.move_to_next_leaf(window)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.51, w = 0.48, h = 0.48 })
		assert.are.equal(screens[1], window.moved_to_screen)

		virtual_screens.move_to_next_leaf(window)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.01, w = 0.48, h = 0.48 })
		assert.are.equal(screens[1], window.moved_to_screen)

		virtual_screens.move_to_next_leaf(window)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.51, w = 0.48, h = 0.48 })
		assert.are.equal(screens[1], window.moved_to_screen)
	end)

	it("moves to the next physical screen only after the last fixed-depth leaf", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 2, 2 })

		virtual_screens.move_to_next_leaf(window)

		assert.are.equal(screens[2], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.01, w = 0.48, h = 0.48 })
	end)

	it("wraps from the final leaf on the final physical screen back to the first physical screen", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 2, 2 }, 2)

		virtual_screens.move_to_next_leaf(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.01, w = 0.48, h = 0.48 })
	end)

	it("uses floating dimensions inside the current path", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})

		virtual_screens.move_to_path(window, { 2 })

		assert_unit(window.moved_to_unit, { x = 0.55, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("toggles between floating and fixed while preserving floating dimensions", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.move_to_path(window, { 2 })

		virtual_screens.toggle_floating(window)
		virtual_screens.reapply_window(window)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })

		virtual_screens.toggle_floating(window)
		virtual_screens.reapply_window(window)
		assert_unit(window.moved_to_unit, { x = 0.55, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("changes the global gap and reapplies all known windows", function()
		local slack = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		local kitty = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })

		virtual_screens.configure_window(slack, { mode = "fixed", default_path = { 1 } })
		virtual_screens.configure_window(kitty, { mode = "fixed" })
		virtual_screens.increase_gap()
		virtual_screens.reapply_all_windows()

		assert_unit(slack.moved_to_unit, { x = 0.0125, y = 0.025, w = 0.475, h = 0.95 })
		assert_unit(kitty.moved_to_unit, { x = 0.025, y = 0.025, w = 0.95, h = 0.95 })
	end)

	it("clamps the global gap at zero", function()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()

		assert.are.equal(0, virtual_screens.get_gap())
	end)

	it("logs gap changes", function()
		local messages = {}
		debug_log.set_sink(function(...)
			messages[#messages + 1] = { ... }
		end)
		virtual_screens.set_debug(true)

		virtual_screens.increase_gap()
		virtual_screens.decrease_gap()

		virtual_screens.set_debug(false)
		assert.are.same({
			{ "Virtual screen gap is now 0.025" },
			{ "Virtual screen gap is now 0.02" },
		}, messages)
	end)

	it("returns the selected physical screen for a known window", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_path(window, { 1 }, 2)

		assert.are.equal(screens[2], virtual_screens.get_physical_screen_for_window(window))
	end)

	it("falls back to the window's current screen when no virtual state exists", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })

		assert.are.equal(screens[1], virtual_screens.get_physical_screen_for_window(window))
	end)
end)

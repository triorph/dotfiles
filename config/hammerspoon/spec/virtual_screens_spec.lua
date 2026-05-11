local function assert_unit(actual, expected)
	local epsilon = 0.000001
	for _, key in ipairs({ "x", "y", "w", "h" }) do
		assert.is_true(
			math.abs(actual[key] - expected[key]) <= epsilon,
			"expected " .. key .. "=" .. tostring(expected[key]) .. ", got " .. tostring(actual[key])
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
			x = rect.x - self._frame.x,
			y = rect.y - self._frame.y,
			w = rect.w,
			h = rect.h,
		}
	end

	return screen
end

local function make_window(screen, frame)
	local window = {
		_screen = screen,
		_frame = frame,
		moved_to_screen = nil,
		moved_to_unit = nil,
	}

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

		package.loaded["virtual_screens"] = nil
		virtual_screens = require("virtual_screens")
		virtual_screens.set_debug(false)
	end)

	it("defaults the current virtual screen to one on a single unsplit screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		assert.are.equal(1, virtual_screens.get_current_virtual_screen(window))
	end)

	it("keeps the window on the current real screen and uses the provided unit when moving without a virtual target", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		local unit = { x = 0.1, y = 0.2, w = 0.3, h = 0.4 }

		virtual_screens.move_to_virtual_screen(window, nil, unit)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, unit)
	end)

	it("applies the configured gap to fixed windows on an unsplit screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.02, y = 0.02, w = 0.96, h = 0.96 })
	end)

	it("applies default path placement for newly configured fixed windows", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, {
			mode = "fixed",
			default_path = { 1 },
		})
		virtual_screens.move_to_virtual_screen(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("creates parent splits implied by a deeper default path", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.configure_window(window, {
			mode = "fixed",
			default_path = { 1, 2 },
		})
		virtual_screens.move_to_virtual_screen(window)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.51, w = 0.48, h = 0.48 })
	end)

	it("wraps to virtual screen one when asking for next on a single unsplit physical screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		assert.are.equal(1, virtual_screens.get_next_virtual_screen(window))
	end)

	it("splits the current real screen into left and right halves when virtual screens are increased", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 1)
		assert.are.equal(1, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))
	end)

	it("uses fixed mode with edge padding when moving to the second virtual screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(window, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(window, 2)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("uses a configurable gap for fixed split windows", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.increase_gap()
		virtual_screens.configure_window(window, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(window, 2)

		assert_unit(window.moved_to_unit, { x = 0.5125, y = 0.025, w = 0.475, h = 0.95 })
	end)

	it("logs the current gap when increasing it", function()
		local messages = {}
		local original_print = _G.print
		_G.print = function(...)
			messages[#messages + 1] = { ... }
		end
		virtual_screens.set_debug(true)

		virtual_screens.increase_gap()

		_G.print = original_print
		virtual_screens.set_debug(false)
		assert.are.same({ { "Virtual screen gap is now 0.025" } }, messages)
	end)

	it("does not decrease the configurable gap below zero", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.decrease_gap()
		virtual_screens.configure_window(window, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(window, 2)

		assert_unit(window.moved_to_unit, { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("logs the current gap when decreasing it", function()
		local messages = {}
		local original_print = _G.print
		_G.print = function(...)
			messages[#messages + 1] = { ... }
		end
		virtual_screens.set_debug(true)

		virtual_screens.decrease_gap()

		_G.print = original_print
		virtual_screens.set_debug(false)
		assert.are.same({ { "Virtual screen gap is now 0.015" } }, messages)
	end)

	it("uses floating mode dimensions inside the target virtual screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.move_to_virtual_screen(window, 2)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.55, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("treats a legacy unit argument as floating dimensions inside the target virtual screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 2, { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.55, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("remembers floating mode for later moves without a unit argument", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.move_to_virtual_screen(window, 2)
		virtual_screens.move_to_virtual_screen(window, 1)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.05, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("toggles a floating window to fixed mode", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.toggle_floating(window)
		virtual_screens.move_to_virtual_screen(window, 2)

		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("toggles a fixed window back to its remembered floating mode", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window
		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.toggle_floating(window)
		virtual_screens.toggle_floating(window)
		virtual_screens.move_to_virtual_screen(window, 2)

		assert_unit(window.moved_to_unit, { x = 0.55, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("preserves floating dimensions relative to the current region when virtual screens increase", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.increase_virtual_screens()
		virtual_screens.move_to_virtual_screen(window)

		assert_unit(window.moved_to_unit, { x = 0.05, y = 0.1, w = 0.4, h = 0.8 })
	end)

	it("preserves floating dimensions relative to the current region when virtual screens decrease", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.configure_window(window, {
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		})
		virtual_screens.increase_virtual_screens()
		virtual_screens.decrease_virtual_screens()
		virtual_screens.move_to_virtual_screen(window)

		assert_unit(window.moved_to_unit, { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
	end)

	it("returns to a single full-screen virtual screen after increasing and then decreasing", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.decrease_virtual_screens()

		local right_side_window = make_window(screens[1], { x = 600, y = 100, w = 100, h = 100 })
		assert.are.equal(1, virtual_screens.get_current_virtual_screen(right_side_window))
	end)

	it("assigns the second physical screen to virtual screen two by default", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[2], { x = 1100, y = 100, w = 400, h = 400 })

		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))
	end)

	it("moves virtual screen two to the second physical screen when two physical screens exist", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })

		virtual_screens.move_to_virtual_screen(window, 2)

		assert.are.equal(screens[2], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.02, y = 0.02, w = 0.96, h = 0.96 })
	end)

	it("wraps from the second physical screen back to virtual screen one", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local window = make_window(screens[2], { x = 1100, y = 100, w = 400, h = 400 })

		assert.are.equal(1, virtual_screens.get_next_virtual_screen(window))
	end)

	it("splits the currently occupied region along its largest edge when adding a third virtual screen", function()
		local window = make_window(screens[1], { x = 600, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 3)
		assert.are.equal(3, virtual_screens.get_current_virtual_screen(window))
	end)

	it("supports moving to a fifth generated virtual screen", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 5)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("splits the frontmost window's currently occupied virtual region", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 1)
		assert.are.equal(1, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 3)
		assert.are.equal(3, virtual_screens.get_current_virtual_screen(window))
	end)

	it("moves to the next virtual screen using depth-first leaf traversal", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 1)
		assert.are.equal(2, virtual_screens.get_next_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(3, virtual_screens.get_next_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 3)
		assert.are.equal(1, virtual_screens.get_next_virtual_screen(window))
	end)

	it("decreasing virtual screens removes the last virtual screen and wraps within the reduced count", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 400, h = 400 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		virtual_screens.decrease_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 4)

		assert.are.equal(4, virtual_screens.get_current_virtual_screen(window))
		assert.are.equal(1, virtual_screens.get_next_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 4)

		assert.are.equal(screens[1], window.moved_to_screen)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("decreasing from the newly split active region merges it back into its parent size", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		window:setFrame({ x = 100, y = 600, w = 100, h = 100 })
		virtual_screens.decrease_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 1)
		assert.are.equal(1, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 1)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })

		virtual_screens.move_to_virtual_screen(window, 2)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("decreasing from a sibling active region merges the newest region back into that sibling", function()
		local window = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = window

		virtual_screens.increase_virtual_screens()
		virtual_screens.increase_virtual_screens()
		window:setFrame({ x = 100, y = 100, w = 100, h = 100 })
		virtual_screens.decrease_virtual_screens()

		virtual_screens.move_to_virtual_screen(window, 1)
		assert.are.equal(1, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 2)
		assert.are.equal(2, virtual_screens.get_current_virtual_screen(window))

		virtual_screens.move_to_virtual_screen(window, 1)
		assert_unit(window.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })

		virtual_screens.move_to_virtual_screen(window, 2)
		assert_unit(window.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })
	end)

	it("keeps virtual split trees independent per window", function()
		local slack = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		local kitty = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = slack

		virtual_screens.increase_virtual_screens()

		virtual_screens.configure_window(slack, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(slack, 2)
		assert_unit(slack.moved_to_unit, { x = 0.51, y = 0.02, w = 0.48, h = 0.96 })

		virtual_screens.configure_window(kitty, { mode = "fixed" })
		virtual_screens.move_to_virtual_screen(kitty)
		assert_unit(kitty.moved_to_unit, { x = 0.02, y = 0.02, w = 0.96, h = 0.96 })
	end)

	it("uses each window's own split tree when finding the next virtual screen", function()
		local slack = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		local kitty = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = slack

		virtual_screens.increase_virtual_screens()

		assert.are.equal(2, virtual_screens.get_next_virtual_screen(slack))
		assert.are.equal(1, virtual_screens.get_next_virtual_screen(kitty))
	end)

	it("traverses a window's split tree across physical screens", function()
		screens[2] = make_screen("secondary", { x = 1000, y = 0, w = 1000, h = 1000 })
		local slack = make_window(screens[1], { x = 100, y = 100, w = 100, h = 100 })
		frontmost_window = slack

		virtual_screens.increase_virtual_screens()

		assert.are.equal(2, virtual_screens.get_next_virtual_screen(slack))
		virtual_screens.move_to_virtual_screen(slack, 3)

		assert.are.equal(screens[2], slack.moved_to_screen)
		assert_unit(slack.moved_to_unit, { x = 0.01, y = 0.02, w = 0.48, h = 0.96 })
	end)
end)

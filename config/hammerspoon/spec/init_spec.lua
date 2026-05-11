describe("init", function()
	local bindings
	local calls
	local frontmost_window

	local function same_modifiers(actual, expected)
		if #actual ~= #expected then
			return false
		end
		for i, modifier in ipairs(expected) do
			if actual[i] ~= modifier then
				return false
			end
		end
		return true
	end

	local function find_binding(modifiers, key)
		for _, binding in ipairs(bindings) do
			if binding.key == key and same_modifiers(binding.modifiers, modifiers) then
				return binding.callback
			end
		end
		error("binding not found for " .. table.concat(modifiers, "+") .. "+" .. key)
	end

	before_each(function()
		bindings = {}
		calls = {}
		frontmost_window = { name = "frontmost" }

		_G.spoon = {
			ReloadConfiguration = {
				start = function()
					calls[#calls + 1] = { name = "reload_start" }
				end,
			},
			Caffeine = {
				bindHotkeys = function(_, mapping)
					calls[#calls + 1] = { name = "caffeine_bind", mapping = mapping }
				end,
				start = function()
					calls[#calls + 1] = { name = "caffeine_start" }
				end,
			},
		}

		_G.hs = {
			loadSpoon = function(name)
				calls[#calls + 1] = { name = "load_spoon", spoon = name }
			end,
			hotkey = {
				bind = function(modifiers, key, callback)
					bindings[#bindings + 1] = {
						modifiers = modifiers,
						key = key,
						callback = callback,
					}
				end,
			},
			window = {
				frontmostWindow = function()
					return frontmost_window
				end,
			},
		}

		package.loaded["init"] = nil
		package.loaded["debug_log"] = nil
		require("debug_log").set_enabled(false)
		package.loaded["virtual_screens"] = nil
		package.preload["virtual_screens"] = function()
			return {
				move_to_next_leaf = function(window)
					calls[#calls + 1] = { name = "move_next", window = window }
				end,
				reapply_window = function(window)
					calls[#calls + 1] = { name = "reapply", window = window }
				end,
				reapply_all_windows = function()
					calls[#calls + 1] = { name = "reapply_all" }
				end,
				move_to_path = function(window, path, physical_screen_index)
					calls[#calls + 1] = { name = "move", window = window, path = path, physical_screen_index = physical_screen_index }
				end,
				configure_window = function(window, config)
					calls[#calls + 1] = { name = "configure", window = window, config = config }
				end,
				increase_virtual_screens = function()
					calls[#calls + 1] = { name = "increase" }
				end,
				decrease_virtual_screens = function()
					calls[#calls + 1] = { name = "decrease" }
				end,
				increase_gap = function()
					calls[#calls + 1] = { name = "increase_gap" }
				end,
				decrease_gap = function()
					calls[#calls + 1] = { name = "decrease_gap" }
				end,
				toggle_floating = function(window)
					calls[#calls + 1] = { name = "toggle_floating", window = window }
				end,
			}
		end

		for _, module in ipairs({ "toggle_window", "newwp", "bluetooth", "midi" }) do
			package.loaded[module] = nil
			package.preload[module] = function()
				calls[#calls + 1] = { name = "require", module = module }
				return true
			end
		end
	end)

	after_each(function()
		for _, module in ipairs({ "virtual_screens", "toggle_window", "newwp", "bluetooth", "midi" }) do
			package.preload[module] = nil
		end
	end)

	it("binds the root virtual screen hotkeys", function()
		require("init")

		assert.is_function(find_binding({ "ctrl", "alt" }, "m"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "b"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "f"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "="))
		assert.is_function(find_binding({ "ctrl", "alt" }, "-"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "]"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "["))
	end)

	it("moves the frontmost window to the next virtual screen", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "m")()

		assert.are.same({ name = "move_next", window = frontmost_window }, calls[#calls])
	end)

	it("configures the frontmost window as fixed when embiggening", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "b")()

		assert.are.same({ name = "configure", window = frontmost_window, config = { mode = "fixed" } }, calls[#calls - 1])
		assert.are.same({ name = "reapply", window = frontmost_window }, calls[#calls])
	end)

	it("toggles floating mode and reapplies the frontmost window layout", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "f")()

		assert.are.same({ name = "toggle_floating", window = frontmost_window }, calls[#calls - 1])
		assert.are.same({ name = "reapply", window = frontmost_window }, calls[#calls])
	end)

	it("increases virtual screens without reconfiguring the frontmost window", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "=")()

		assert.are.same({ name = "increase" }, calls[#calls - 1])
		assert.are.same({ name = "reapply", window = frontmost_window }, calls[#calls])
	end)

	it("decreases virtual screens without reconfiguring the frontmost window", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "-")()

		assert.are.same({ name = "decrease" }, calls[#calls - 1])
		assert.are.same({ name = "reapply", window = frontmost_window }, calls[#calls])
	end)

	it("increases the gap and reapplies every known window layout", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "]")()

		assert.are.same({ name = "increase_gap" }, calls[#calls - 1])
		assert.are.same({ name = "reapply_all" }, calls[#calls])
	end)

	it("decreases the gap and reapplies every known window layout", function()
		require("init")

		find_binding({ "ctrl", "alt" }, "[")()

		assert.are.same({ name = "decrease_gap" }, calls[#calls - 1])
		assert.are.same({ name = "reapply_all" }, calls[#calls])
	end)

	it("does nothing for frontmost-window hotkeys when no window is focused", function()
		frontmost_window = nil
		require("init")

		find_binding({ "ctrl", "alt" }, "m")()
		find_binding({ "ctrl", "alt" }, "b")()
		find_binding({ "ctrl", "alt" }, "f")()

		for _, call in ipairs(calls) do
			assert.is_not.equal("move_next", call.name)
			assert.is_not.equal("configure", call.name)
			assert.is_not.equal("toggle_floating", call.name)
			assert.is_not.equal("reapply", call.name)
		end
	end)
end)

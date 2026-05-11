describe("toggle_window", function()
	local bindings
	local configured_windows
	local moved_windows
	local launched_apps
	local apps
	local host_name

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

	local function make_app(name)
		local window = { name = name .. " window" }
		return {
			window = window,
			frontmost = false,
			activated = false,
			hidden = false,
			selected_menu_item = nil,
			mainWindow = function(self)
				return self.window
			end,
			focusedWindow = function(self)
				return self.window
			end,
			isFrontmost = function(self)
				return self.frontmost
			end,
			activate = function(self)
				self.frontmost = true
				self.activated = true
			end,
			hide = function(self)
				self.frontmost = false
				self.hidden = true
			end,
			name = function(self)
				return name
			end,
			selectMenuItem = function(self, item)
				self.selected_menu_item = item
			end,
		}
	end

	before_each(function()
		bindings = {}
		configured_windows = {}
		moved_windows = {}
		launched_apps = {}
		host_name = "test-host"
		apps = {
			["zoom.us"] = make_app("zoom.us"),
			["Slack"] = make_app("Slack"),
		}

		_G.hs = {
			host = {
				localizedName = function()
					return host_name
				end,
			},
			hotkey = {
				bind = function(modifiers, key, callback)
					bindings[#bindings + 1] = {
						modifiers = modifiers,
						key = key,
						callback = callback,
					}
				end,
			},
			application = {
				get = function(name)
					return apps[name]
				end,
				open = function(name)
					launched_apps[#launched_apps + 1] = name
					apps[name] = apps[name] or make_app(name)
					return apps[name]
				end,
			},
		}

		package.loaded["toggle_window"] = nil
		package.loaded["debug_log"] = nil
		package.loaded["virtual_screens"] = nil
		package.preload["debug_log"] = function()
			return { log = function() end, set_enabled = function() end }
		end
		package.preload["virtual_screens"] = function()
			return {
				configure_window = function(window, config)
					configured_windows[#configured_windows + 1] = { window = window, config = config }
				end,
				move_to_virtual_screen = function(window)
					moved_windows[#moved_windows + 1] = window
				end,
			}
		end
	end)

	after_each(function()
		package.preload["virtual_screens"] = nil
	end)

	it("configures nil-unit app bindings as fixed windows", function()
		require("toggle_window")

		find_binding({ "ctrl", "alt" }, "z")()

		assert.are.equal(apps["zoom.us"].window, configured_windows[1].window)
		assert.are.same({ mode = "fixed" }, configured_windows[1].config)
		assert.are.equal(apps["zoom.us"].window, moved_windows[1])
	end)

	it("configures custom-unit app bindings as floating windows", function()
		require("toggle_window")

		find_binding({ "ctrl" }, "s")()

		assert.are.equal(apps["Slack"].window, configured_windows[1].window)
		assert.are.same({
			mode = "floating",
			floating_unit = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
		}, configured_windows[1].config)
		assert.are.equal(apps["Slack"].window, moved_windows[1])
	end)

	it("hides an existing frontmost non-Arc app", function()
		apps["Slack"].frontmost = true
		require("toggle_window")

		find_binding({ "ctrl" }, "s")()

		assert.is_true(apps["Slack"].hidden)
		assert.is_false(apps["Slack"].frontmost)
	end)

	it("activates an existing non-frontmost app", function()
		apps["Slack"].frontmost = false
		require("toggle_window")

		find_binding({ "ctrl" }, "s")()

		assert.is_true(apps["Slack"].activated)
		assert.is_true(apps["Slack"].frontmost)
	end)

	it("launches a missing app by app name", function()
		apps["Slack"] = nil
		require("toggle_window")

		find_binding({ "ctrl" }, "s")()

		assert.are.same({ "Slack" }, launched_apps)
		assert.are.equal(apps["Slack"].window, moved_windows[1])
	end)

	it("launches a missing app with its launcher name override", function()
		host_name = "CJDPHHJW5Q"
		apps["IntelliJ IDEA"] = nil
		require("toggle_window")

		find_binding({ "ctrl", "alt" }, "d")()

		assert.are.same({ "IntelliJ IDEA Ultimate" }, launched_apps)
	end)

	it("uses the Arc hide menu item instead of generic hide", function()
		host_name = "CJDPHHJW5Q"
		apps["Arc"] = make_app("Arc")
		apps["Arc"].frontmost = true
		require("toggle_window")

		find_binding({ "ctrl" }, "tab")()

		assert.are.equal("Hide Arc", apps["Arc"].selected_menu_item)
		assert.is_false(apps["Arc"].hidden)
	end)
end)

describe("newwp", function()
	local bindings
	local screens
	local http_gets
	local opened_files
	local written_files
	local desktop_urls
	local original_getenv
	local frontmost_window
	local selected_screen

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

	local function make_screen(name)
		return {
			name = name,
			desktopImageURL = function(self, url)
				desktop_urls[#desktop_urls + 1] = { screen = self, url = url }
			end,
		}
	end

	before_each(function()
		bindings = {}
		screens = { make_screen("one"), make_screen("two") }
		http_gets = {}
		opened_files = {}
		written_files = {}
		desktop_urls = {}

		frontmost_window = {
			screen = function()
				return screens[1]
			end,
		}
		selected_screen = screens[2]

		_G.hs = {
			json = {
				read = function(path)
					assert.are.equal("~/.config/wallhaven.json", path)
					return { username = "user", collection_id = "collection", api_key = "secret" }
				end,
				decode = function(body)
					if body == "meta" then
						return { meta = { per_page = 2, total = 5 } }
					end
					return {
						data = {
							{ path = "https://images.example/first.jpg" },
							{ path = "https://images.example/second.jpg" },
						},
					}
				end,
			},
			http = {
				get = function(url)
					http_gets[#http_gets + 1] = url
					if url:match("wallhaven") then
						local wallhaven_call_count = 0
						for _, called_url in ipairs(http_gets) do
							if called_url:match("wallhaven") then
								wallhaven_call_count = wallhaven_call_count + 1
							end
						end
						return 200, wallhaven_call_count % 2 == 1 and "meta" or "data", {}
					end
					return 200, "image-body", {}
				end,
			},
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
			hotkey = {
				bind = function(modifiers, key, callback)
					bindings[#bindings + 1] = { modifiers = modifiers, key = key, callback = callback }
				end,
			},
		}

		_G.os = _G.os or {}
		original_getenv = os.getenv
		os.getenv = function(name)
			if name == "HOME" then
				return "/home/test"
			end
			return original_getenv(name)
		end

		_G.io_open_original_for_newwp_spec = io.open
		io.open = function(path, mode)
			if not path:match("/%.wallpapers/") then
				return _G.io_open_original_for_newwp_spec(path, mode)
			end
			opened_files[#opened_files + 1] = { path = path, mode = mode }
			if mode == "r" then
				return nil, "missing"
			end
			local file = {
				write = function(_, body)
					written_files[#written_files + 1] = { path = path, body = body }
				end,
				close = function() end,
			}
			return file
		end

		package.loaded["newwp"] = nil
		package.loaded["virtual_screens"] = nil
		package.preload["virtual_screens"] = function()
			return {
				get_physical_screen_for_window = function(window)
					if window == frontmost_window then
						return selected_screen
					end
					return nil
				end,
			}
		end
		package.loaded["debug_log"] = nil
		require("debug_log").set_enabled(false)
	end)

	after_each(function()
		os.getenv = original_getenv
		io.open = _G.io_open_original_for_newwp_spec
		_G.io_open_original_for_newwp_spec = nil
		package.loaded["newwp"] = nil
		_G.newwp = nil
	end)

	it("binds the wallpaper hotkeys", function()
		require("newwp")

		assert.is_function(find_binding({ "ctrl", "cmd", "alt" }, "w"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "w"))
	end)

	it("sets wallpaper for the active window's selected physical screen", function()
		require("newwp")

		find_binding({ "ctrl", "alt" }, "w")(1)

		assert.are.equal(screens[2], desktop_urls[1].screen)
		assert.are.equal("file:///home/test/.wallpapers/second.jpg", desktop_urls[1].url)
	end)

	it("falls back to the active window's current screen when virtual screens has no selected screen", function()
		selected_screen = nil
		require("newwp")

		find_binding({ "ctrl", "alt" }, "w")(1)

		assert.are.equal(screens[1], desktop_urls[1].screen)
		assert.are.equal("file:///home/test/.wallpapers/second.jpg", desktop_urls[1].url)
	end)

	it("does nothing for active-screen wallpaper when no window is focused", function()
		frontmost_window = nil
		require("newwp")

		find_binding({ "ctrl", "alt" }, "w")(1)

		assert.are.equal(0, #desktop_urls)
	end)

	it("sets wallpaper for a numeric screen index", function()
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(1, 2)

		assert.are.equal(screens[2], desktop_urls[1].screen)
		assert.are.equal("file:///home/test/.wallpapers/second.jpg", desktop_urls[1].url)
	end)

	it("fetches collection metadata and the selected page using configured credentials", function()
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(3, screens[1])

		assert.are.equal("https://wallhaven.cc/api/v1/collections/user/collection/?apikey=secret&page=0", http_gets[1])
		assert.are.equal("https://wallhaven.cc/api/v1/collections/user/collection/?apikey=secret&page=1", http_gets[2])
	end)

	it("downloads the image when it is not already cached", function()
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(1, screens[1])

		assert.are.equal("https://images.example/second.jpg", http_gets[3])
		assert.are.same({ path = "/home/test/.wallpapers/second.jpg", body = "image-body" }, written_files[1])
	end)

	it("applies wallpaper to every screen when no screen is provided", function()
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(0)

		assert.are.equal(2, #desktop_urls)
		assert.are.equal(screens[1], desktop_urls[1].screen)
		assert.are.equal(screens[2], desktop_urls[2].screen)
	end)

	it("does nothing when the requested numeric screen does not exist", function()
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(0, 99)

		assert.are.equal(0, #http_gets)
		assert.are.equal(0, #desktop_urls)
	end)

	it("does nothing when wallpaper config is missing", function()
		hs.json.read = function()
			return nil
		end
		require("newwp")

		find_binding({ "ctrl", "cmd", "alt" }, "w")(0, screens[1])

		assert.are.equal(0, #desktop_urls)
	end)
end)

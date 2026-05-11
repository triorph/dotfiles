describe("newwp", function()
	local bindings
	local screens
	local http_gets
	local opened_files
	local written_files
	local desktop_urls
	local original_getenv

	local function find_binding(modifiers, key)
		for _, binding in ipairs(bindings) do
			if binding.key == key then
				return binding.callback
			end
		end
		error("binding not found for " .. key)
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

	it("binds the wallpaper hotkey", function()
		require("newwp")

		assert.is_function(find_binding({ "ctrl", "cmd", "alt" }, "w"))
	end)

	it("sets wallpaper for a numeric screen index", function()
		require("newwp")

		newwp(1, 2)

		assert.are.equal(screens[2], desktop_urls[1].screen)
		assert.are.equal("file:///home/test/.wallpapers/second.jpg", desktop_urls[1].url)
	end)

	it("fetches collection metadata and the selected page using configured credentials", function()
		require("newwp")

		newwp(3, screens[1])

		assert.are.equal("https://wallhaven.cc/api/v1/collections/user/collection/?apikey=secret&page=0", http_gets[1])
		assert.are.equal("https://wallhaven.cc/api/v1/collections/user/collection/?apikey=secret&page=1", http_gets[2])
	end)

	it("downloads the image when it is not already cached", function()
		require("newwp")

		newwp(1, screens[1])

		assert.are.equal("https://images.example/second.jpg", http_gets[3])
		assert.are.same({ path = "/home/test/.wallpapers/second.jpg", body = "image-body" }, written_files[1])
	end)

	it("applies wallpaper to every screen when no screen is provided", function()
		require("newwp")

		newwp(0)

		assert.are.equal(2, #desktop_urls)
		assert.are.equal(screens[1], desktop_urls[1].screen)
		assert.are.equal(screens[2], desktop_urls[2].screen)
	end)
end)

describe("midi", function()
	local device_callback
	local midi_instances
	local key_strokes
	local now
	local garageband

	local function registered_callback()
		return midi_instances[1].registered_callback
	end

	before_each(function()
		midi_instances = {}
		key_strokes = {}
		now = 0
		garageband = {
			mainWindow = function()
				return true
			end,
		}

		_G.hs = {
			timer = {
				absoluteTime = function()
					return now
				end,
			},
			midi = {
				deviceCallback = function(callback)
					device_callback = callback
				end,
				new = function(device)
					local instance = { device = device }
					function instance:callback(callback)
						self.registered_callback = callback
					end
					midi_instances[#midi_instances + 1] = instance
					return instance
				end,
			},
			application = {
				get = function(name)
					if name == "GarageBand" then
						return garageband
					end
					return nil
				end,
			},
			eventtap = {
				keyStroke = function(modifiers, key, delay, app)
					key_strokes[#key_strokes + 1] = { modifiers = modifiers, key = key, delay = delay, app = app }
				end,
			},
		}

		package.loaded["midi"] = nil
		package.loaded["debug_log"] = nil
		require("debug_log").set_enabled(false)
	end)

	after_each(function()
		package.loaded["midi"] = nil
	end)

	it("registers a MIDI device callback", function()
		require("midi")

		assert.is_function(device_callback)
	end)

	it("registers callbacks only for the FootCtrl device", function()
		require("midi")

		device_callback({ "Other", "FootCtrl" }, {})

		assert.are.equal(1, #midi_instances)
		assert.are.equal("FootCtrl", midi_instances[1].device)
		assert.is_function(midi_instances[1].registered_callback)
	end)

	it("maps FootCtrl program changes to GarageBand key strokes", function()
		require("midi")
		device_callback({ "FootCtrl" }, {})
		local callback = registered_callback()
		local expected = {
			[1] = { modifiers = nil, key = "up" },
			[2] = { modifiers = nil, key = "down" },
			[3] = { modifiers = nil, key = "r" },
			[4] = { modifiers = nil, key = "space" },
			[5] = { modifiers = nil, key = "right" },
			[6] = { modifiers = nil, key = "delete" },
			[7] = { modifiers = { "cmd" }, key = "z" },
			[8] = { modifiers = nil, key = "m" },
		}

		for program_number = 1, 8 do
			now = program_number * 300 * 1000 * 1000
			callback(nil, "FootCtrl", "programChange", nil, { channel = 0, programNumber = program_number })
			assert.are.same(expected[program_number].modifiers, key_strokes[program_number].modifiers)
			assert.are.equal(expected[program_number].key, key_strokes[program_number].key)
			assert.are.equal(garageband, key_strokes[program_number].app)
		end
	end)

	it("debounces rapid repeated MIDI events", function()
		require("midi")
		device_callback({ "FootCtrl" }, {})
		local callback = registered_callback()

		now = 300 * 1000 * 1000
		callback(nil, "FootCtrl", "programChange", nil, { channel = 0, programNumber = 1 })
		now = 350 * 1000 * 1000
		callback(nil, "FootCtrl", "programChange", nil, { channel = 0, programNumber = 2 })

		assert.are.equal(1, #key_strokes)
		assert.are.equal("up", key_strokes[1].key)
	end)

	it("ignores non-FootCtrl events and wrong channels", function()
		require("midi")
		device_callback({ "FootCtrl" }, {})
		local callback = registered_callback()

		now = 300 * 1000 * 1000
		callback(nil, "Other", "programChange", nil, { channel = 0, programNumber = 1 })
		now = 600 * 1000 * 1000
		callback(nil, "FootCtrl", "programChange", nil, { channel = 1, programNumber = 1 })

		assert.are.equal(0, #key_strokes)
	end)

	it("ignores events when GarageBand is not open or has no main window", function()
		require("midi")
		device_callback({ "FootCtrl" }, {})
		local callback = registered_callback()

		garageband = nil
		now = 300 * 1000 * 1000
		callback(nil, "FootCtrl", "programChange", nil, { channel = 0, programNumber = 1 })

		garageband = { mainWindow = function() return nil end }
		now = 600 * 1000 * 1000
		callback(nil, "FootCtrl", "programChange", nil, { channel = 0, programNumber = 1 })

		assert.are.equal(0, #key_strokes)
	end)
end)

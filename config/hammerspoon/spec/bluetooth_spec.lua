describe("bluetooth", function()
	local bindings
	local tasks
	local watcher_callback
	local watcher_started

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

	local function task_args(index)
		return tasks[index].args
	end

	before_each(function()
		bindings = {}
		tasks = {}
		watcher_callback = nil
		watcher_started = false

		_G.hs = {
			task = {
				new = function(path, completion_callback, stream_callback, args)
					local task = {
						path = path,
						completion_callback = completion_callback,
						stream_callback = stream_callback,
						args = args,
						started = false,
						waited = false,
					}
					function task:start()
						self.started = true
					end
					function task:waitUntilExit()
						self.waited = true
					end
					tasks[#tasks + 1] = task
					return task
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
			caffeinate = {
				watcher = {
					systemWillSleep = "systemWillSleep",
					screensDidWake = "screensDidWake",
					new = function(callback)
						watcher_callback = callback
						return {
							start = function()
								watcher_started = true
							end,
						}
					end,
				},
			},
		}

		package.loaded["bluetooth"] = nil
		package.loaded["debug_log"] = nil
		require("debug_log").set_enabled(false)
	end)

	after_each(function()
		package.loaded["bluetooth"] = nil
	end)

	it("starts a caffeinate watcher", function()
		require("bluetooth")

		assert.is_function(watcher_callback)
		assert.is_true(watcher_started)
	end)

	it("binds bluetooth hotkeys", function()
		require("bluetooth")

		assert.is_function(find_binding({ "ctrl", "alt" }, "h"))
		assert.is_function(find_binding({ "ctrl", "alt", "cmd" }, "h"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "e"))
		assert.is_function(find_binding({ "ctrl", "alt", "cmd" }, "e"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "a"))
		assert.is_function(find_binding({ "ctrl", "alt", "cmd" }, "a"))
		assert.is_function(find_binding({ "ctrl", "alt" }, "p"))
		assert.is_function(find_binding({ "ctrl", "alt", "cmd" }, "p"))
	end)

	it("connects and disconnects headphones", function()
		require("bluetooth")

		find_binding({ "ctrl", "alt" }, "h")()
		find_binding({ "ctrl", "alt", "cmd" }, "h")()

		assert.are.same({ "--connect", "88-c9-e8-37-35-61", "--wait-disconnect", "b0-f1-d8-ac-3f-ba" }, task_args(1))
		assert.are.same({ "--disconnect", "88-c9-e8-37-35-61", "--wait-disconnect", "88-c9-e8-37-35-61" }, task_args(2))
	end)

	it("connects and disconnects earbuds", function()
		require("bluetooth")

		find_binding({ "ctrl", "alt" }, "e")()
		find_binding({ "ctrl", "alt", "cmd" }, "e")()

		assert.are.same({ "--connect", "f8-4e-17-ee-97-9f", "--wait-connect", "f8-4e-17-ee-97-9f" }, task_args(1))
		assert.are.same({ "--disconnect", "f8-4e-17-ee-97-9f", "--wait-disconnect", "f8-4e-17-ee-97-9f" }, task_args(2))
	end)

	it("connects and disconnects airpods", function()
		require("bluetooth")

		find_binding({ "ctrl", "alt" }, "a")()
		find_binding({ "ctrl", "alt", "cmd" }, "a")()

		assert.are.same({ "--connect", "b0-f1-d8-ac-3f-ba", "--wait-connect", "b0-f1-d8-ac-3f-ba" }, task_args(1))
		assert.are.same({ "--disconnect", "b0-f1-d8-ac-3f-ba", "--wait-disconnect", "b0-f1-d8-ac-3f-ba" }, task_args(2))
	end)

	it("turns bluetooth power on and prints paired devices", function()
		require("bluetooth")

		find_binding({ "ctrl", "alt" }, "p")()
		find_binding({ "ctrl", "alt", "cmd" }, "p")()

		assert.are.same({ "--power", "on" }, task_args(1))
		assert.are.same({ "--paired" }, task_args(2))
	end)

	it("turns bluetooth off before sleep and on after wake", function()
		require("bluetooth")

		watcher_callback(hs.caffeinate.watcher.systemWillSleep)
		watcher_callback(hs.caffeinate.watcher.screensDidWake)

		assert.are.same({ "--power", "off" }, task_args(1))
		assert.are.same({ "--power", "on" }, task_args(2))
	end)

	it("runs blueutil tasks synchronously with the expected executable", function()
		require("bluetooth")

		find_binding({ "ctrl", "alt" }, "p")()

		assert.are.equal("/opt/homebrew/bin/blueutil", tasks[1].path)
		assert.is_true(tasks[1].started)
		assert.is_true(tasks[1].waited)
	end)
end)

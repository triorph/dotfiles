describe("debug_log", function()
	local messages
	local debug_log

	before_each(function()
		messages = {}
		package.loaded["debug_log"] = nil
		debug_log = require("debug_log")
		debug_log.set_sink(function(...)
			messages[#messages + 1] = { ... }
		end)
	end)

	after_each(function()
		debug_log.set_sink(nil)
		package.loaded["debug_log"] = nil
	end)

	it("prints messages by default", function()
		debug_log.log("hello", "world")

		assert.are.same({ { "hello", "world" } }, messages)
	end)

	it("can disable messages", function()
		debug_log.set_enabled(false)

		debug_log.log("hidden")

		assert.are.same({}, messages)
	end)

	it("can re-enable messages", function()
		debug_log.set_enabled(false)
		debug_log.set_enabled(true)

		debug_log.log("shown")

		assert.are.same({ { "shown" } }, messages)
	end)

	it("can reset the sink back to print", function()
		local original_print = _G.print
		_G.print = function(...)
			messages[#messages + 1] = { ... }
		end

		debug_log.set_sink(nil)
		debug_log.log("printed")

		_G.print = original_print
		assert.are.same({ { "printed" } }, messages)
	end)
end)

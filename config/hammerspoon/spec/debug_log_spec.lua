describe("debug_log", function()
	local messages
	local debug_log
	local original_print

	before_each(function()
		messages = {}
		original_print = _G.print
		_G.print = function(...)
			messages[#messages + 1] = { ... }
		end
		package.loaded["debug_log"] = nil
		debug_log = require("debug_log")
	end)

	after_each(function()
		_G.print = original_print
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
end)

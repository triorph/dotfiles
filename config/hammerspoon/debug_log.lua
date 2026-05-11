local M = {}

local enabled = true
local sink = print

function M.set_enabled(value)
	enabled = value
end

function M.is_enabled()
	return enabled
end

function M.set_sink(value)
	sink = value or print
end

function M.log(...)
	if enabled then
		sink(...)
	end
end

return M

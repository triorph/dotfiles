local M = {}

local enabled = true

function M.set_enabled(value)
	enabled = value
end

function M.is_enabled()
	return enabled
end

function M.log(...)
	if enabled then
		print(...)
	end
end

return M

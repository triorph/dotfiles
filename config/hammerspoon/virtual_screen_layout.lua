local M = {}

local function copy_path(path)
	local ret = {}
	for i, part in ipairs(path or {}) do
		ret[i] = part
	end
	return ret
end

local function split_rect(rect, screen)
	local physical_width = rect.w * screen.w
	local physical_height = rect.h * screen.h

	if physical_width >= physical_height then
		local half_width = rect.w / 2
		return {
			[1] = { x = rect.x, y = rect.y, w = half_width, h = rect.h },
			[2] = { x = rect.x + half_width, y = rect.y, w = half_width, h = rect.h },
		}
	end

	local half_height = rect.h / 2
	return {
		[1] = { x = rect.x, y = rect.y, w = rect.w, h = half_height },
		[2] = { x = rect.x, y = rect.y + half_height, w = rect.w, h = half_height },
	}
end

function M.rect_for_path(path, screen)
	local rect = { x = 0, y = 0, w = 1, h = 1 }
	for _, side in ipairs(path or {}) do
		rect = split_rect(rect, screen)[side]
	end
	return rect
end

function M.first_path(depth)
	local path = {}
	for i = 1, depth do
		path[i] = 1
	end
	return path
end

function M.next_path(path)
	local next_path = copy_path(path)
	for i = #next_path, 1, -1 do
		if next_path[i] == 1 then
			next_path[i] = 2
			for j = i + 1, #next_path do
				next_path[j] = 1
			end
			return next_path
		end
	end
	return nil
end

function M.decrease_path(path)
	local next_path = copy_path(path)
	next_path[#next_path] = nil
	return next_path
end

function M.depth_for_path(path)
	return #(path or {})
end

return M

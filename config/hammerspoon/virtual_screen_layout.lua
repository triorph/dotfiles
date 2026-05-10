local M = {}

local function copy_rect(rect)
	return { x = rect.x, y = rect.y, w = rect.w, h = rect.h }
end

local function copy_path(path)
	local ret = {}
	for i, part in ipairs(path) do
		ret[i] = part
	end
	return ret
end

local function paths_equal(left, right)
	if #left ~= #right then
		return false
	end
	for i, part in ipairs(left) do
		if part ~= right[i] then
			return false
		end
	end
	return true
end

local function node_for_path(root, path)
	local node = root
	for _, part in ipairs(path) do
		if node.children == nil or node.children[part] == nil then
			return nil
		end
		node = node.children[part]
	end
	return node
end

local function resolved_node_for_path(root, path)
	local node = root
	for _, part in ipairs(path) do
		if node.children == nil or node.children[part] == nil then
			return node
		end
		node = node.children[part]
	end
	return node
end

local function make_leaf(node)
	return {
		path = copy_path(node.path),
		rect = copy_rect(node.rect),
	}
end

local function collect_leaves(node, leaves)
	if node.children == nil then
		leaves[#leaves + 1] = make_leaf(node)
		return
	end

	collect_leaves(node.children[1], leaves)
	collect_leaves(node.children[2], leaves)
end

local function split_node(state, node)
	local rect = node.rect
	local physical_width = rect.w * state.screen.w
	local physical_height = rect.h * state.screen.h

	if physical_width >= physical_height then
		local half_width = rect.w / 2
		node.children = {
			[1] = {
				path = copy_path(node.path),
				rect = { x = rect.x, y = rect.y, w = half_width, h = rect.h },
			},
			[2] = {
				path = copy_path(node.path),
				rect = { x = rect.x + half_width, y = rect.y, w = half_width, h = rect.h },
			},
		}
	else
		local half_height = rect.h / 2
		node.children = {
			[1] = {
				path = copy_path(node.path),
				rect = { x = rect.x, y = rect.y, w = rect.w, h = half_height },
			},
			[2] = {
				path = copy_path(node.path),
				rect = { x = rect.x, y = rect.y + half_height, w = rect.w, h = half_height },
			},
		}
	end

	node.children[1].path[#node.children[1].path + 1] = 1
	node.children[2].path[#node.children[2].path + 1] = 2
end

function M.new(screen)
	return {
		screen = { w = screen.w, h = screen.h },
		root = {
			path = {},
			rect = { x = 0, y = 0, w = 1, h = 1 },
		},
	}
end

function M.leaves(state)
	local leaves = {}
	collect_leaves(state.root, leaves)
	return leaves
end

function M.resolve(state, path)
	return make_leaf(resolved_node_for_path(state.root, path))
end

function M.split(state, path)
	local node = node_for_path(state.root, path)
	if node == nil then
		node = resolved_node_for_path(state.root, path)
	end

	if node.children ~= nil then
		return
	end

	split_node(state, node)
end

function M.merge(state, path)
	if #path == 0 then
		return
	end

	local parent_path = copy_path(path)
	parent_path[#parent_path] = nil
	local parent = node_for_path(state.root, parent_path)
	if parent == nil then
		parent = resolved_node_for_path(state.root, parent_path)
	end

	parent.children = nil
end

return M

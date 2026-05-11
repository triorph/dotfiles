local M = {}

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

local function make_leaf(node, rect)
	return {
		path = copy_path(node.path),
		rect = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
	}
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

local function collect_leaves(node, rect, screen, leaves)
	if node.children == nil then
		leaves[#leaves + 1] = make_leaf(node, rect)
		return
	end

	local child_rects = split_rect(rect, screen)
	collect_leaves(node.children[1], child_rects[1], screen, leaves)
	collect_leaves(node.children[2], child_rects[2], screen, leaves)
end

local function split_node(node)
	node.children = {
		[1] = { path = copy_path(node.path) },
		[2] = { path = copy_path(node.path) },
	}
	node.children[1].path[#node.children[1].path + 1] = 1
	node.children[2].path[#node.children[2].path + 1] = 2
end

function M.new()
	return {
		root = {
			path = {},
		},
	}
end

function M.leaves(state, screen)
	local leaves = {}
	collect_leaves(state.root, { x = 0, y = 0, w = 1, h = 1 }, screen, leaves)
	return leaves
end

function M.resolve(state, path, screen)
	local resolved = resolved_node_for_path(state.root, path)
	for _, leaf in ipairs(M.leaves(state, screen)) do
		if paths_equal(leaf.path, resolved.path) then
			return leaf
		end
	end
	return nil
end

function M.split(state, path)
	local node = node_for_path(state.root, path)
	if node == nil then
		node = resolved_node_for_path(state.root, path)
	end

	if node.children ~= nil then
		return
	end

	split_node(node)
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

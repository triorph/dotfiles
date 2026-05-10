local layout = require("virtual_screen_layout")

local function assert_rect(actual, expected)
	assert.are.same(expected, actual)
end

local function assert_paths(actual, expected)
	assert.are.same(expected, actual)
end

local function leaf_paths(state)
	local paths = {}
	for _, leaf in ipairs(layout.leaves(state)) do
		paths[#paths + 1] = leaf.path
	end
	return paths
end

local function leaf_rects(state)
	local rects = {}
	for _, leaf in ipairs(layout.leaves(state)) do
		rects[#rects + 1] = leaf.rect
	end
	return rects
end

local function square_state()
	return layout.new({ w = 1000, h = 1000 })
end

describe("virtual_screen_layout", function()
	it("starts with a single full-screen root leaf", function()
		local state = square_state()

		assert_paths(leaf_paths(state), { {} })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 1, h = 1 })
	end)

	it("splits the root leaf into left and right halves", function()
		local state = square_state()

		layout.split(state, {})

		assert_paths(leaf_paths(state), { { 1 }, { 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.5, h = 1 })
		assert_rect(leaf_rects(state)[2], { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("splits the selected right leaf along its physical largest edge while preserving existing flat indexes", function()
		local state = square_state()
		layout.split(state, {})

		layout.split(state, { 2 })

		assert_paths(leaf_paths(state), { { 1 }, { 2, 1 }, { 2, 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.5, h = 1 })
		assert_rect(leaf_rects(state)[2], { x = 0.5, y = 0, w = 0.5, h = 0.5 })
		assert_rect(leaf_rects(state)[3], { x = 0.5, y = 0.5, w = 0.5, h = 0.5 })
	end)

	it("splits the selected left leaf and flattens leaves in depth-first order on a square screen", function()
		local state = square_state()
		layout.split(state, {})

		layout.split(state, { 1 })

		assert_paths(leaf_paths(state), { { 1, 1 }, { 1, 2 }, { 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.5, h = 0.5 })
		assert_rect(leaf_rects(state)[2], { x = 0, y = 0.5, w = 0.5, h = 0.5 })
		assert_rect(leaf_rects(state)[3], { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("splits by physical edge length, not normalized edge length", function()
		local state = layout.new({ w = 5120, h = 1440 })
		layout.split(state, {})

		layout.split(state, { 1 })

		assert_paths(leaf_paths(state), { { 1, 1 }, { 1, 2 }, { 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.25, h = 1 })
		assert_rect(leaf_rects(state)[2], { x = 0.25, y = 0, w = 0.25, h = 1 })
		assert_rect(leaf_rects(state)[3], { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("resolves a stale path to the deepest existing ancestor", function()
		local state = square_state()
		layout.split(state, {})

		local resolved = layout.resolve(state, { 1, 2, 2 })

		assert_paths({ resolved.path }, { { 1 } })
		assert_rect(resolved.rect, { x = 0, y = 0, w = 0.5, h = 1 })
	end)

	it("merges either child of a split region back into the parent leaf", function()
		local state = square_state()
		layout.split(state, {})
		layout.split(state, { 1 })

		layout.merge(state, { 1, 2 })

		assert_paths(leaf_paths(state), { { 1 }, { 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.5, h = 1 })
		assert_rect(leaf_rects(state)[2], { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("merges a sibling child back into the same parent leaf", function()
		local state = square_state()
		layout.split(state, {})
		layout.split(state, { 1 })

		layout.merge(state, { 1, 1 })

		assert_paths(leaf_paths(state), { { 1 }, { 2 } })
		assert_rect(leaf_rects(state)[1], { x = 0, y = 0, w = 0.5, h = 1 })
		assert_rect(leaf_rects(state)[2], { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)
end)

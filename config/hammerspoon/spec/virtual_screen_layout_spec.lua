local layout = require("virtual_screen_layout")

local function assert_rect(actual, expected)
	assert.are.same(expected, actual)
end

describe("virtual_screen_layout", function()
	local square_screen = { w = 1000, h = 1000 }
	local ultrawide_screen = { w = 5120, h = 1440 }

	it("resolves the root path to the full screen", function()
		assert_rect(layout.rect_for_path({}, square_screen), { x = 0, y = 0, w = 1, h = 1 })
	end)

	it("resolves depth-one paths to left and right halves", function()
		assert_rect(layout.rect_for_path({ 1 }, square_screen), { x = 0, y = 0, w = 0.5, h = 1 })
		assert_rect(layout.rect_for_path({ 2 }, square_screen), { x = 0.5, y = 0, w = 0.5, h = 1 })
	end)

	it("resolves deeper paths by repeatedly splitting the selected region", function()
		assert_rect(layout.rect_for_path({ 1, 1 }, square_screen), { x = 0, y = 0, w = 0.5, h = 0.5 })
		assert_rect(layout.rect_for_path({ 1, 2 }, square_screen), { x = 0, y = 0.5, w = 0.5, h = 0.5 })
		assert_rect(layout.rect_for_path({ 2, 1 }, square_screen), { x = 0.5, y = 0, w = 0.5, h = 0.5 })
		assert_rect(layout.rect_for_path({ 2, 2 }, square_screen), { x = 0.5, y = 0.5, w = 0.5, h = 0.5 })
	end)

	it("splits by physical edge length, not normalized edge length", function()
		assert_rect(layout.rect_for_path({ 1, 1 }, ultrawide_screen), { x = 0, y = 0, w = 0.25, h = 1 })
		assert_rect(layout.rect_for_path({ 1, 2 }, ultrawide_screen), { x = 0.25, y = 0, w = 0.25, h = 1 })
		assert_rect(layout.rect_for_path({ 2, 1 }, ultrawide_screen), { x = 0.5, y = 0, w = 0.25, h = 1 })
		assert_rect(layout.rect_for_path({ 2, 2 }, ultrawide_screen), { x = 0.75, y = 0, w = 0.25, h = 1 })
	end)

	it("returns the first path for a requested depth", function()
		assert.are.same({}, layout.first_path(0))
		assert.are.same({ 1 }, layout.first_path(1))
		assert.are.same({ 1, 1, 1 }, layout.first_path(3))
	end)

	it("moves to the next path like a fixed-depth DFS binary counter", function()
		assert.are.same({ 1, 2 }, layout.next_path({ 1, 1 }))
		assert.are.same({ 2, 1 }, layout.next_path({ 1, 2 }))
		assert.are.same({ 2, 2 }, layout.next_path({ 2, 1 }))
		assert.is_nil(layout.next_path({ 2, 2 }))
	end)

	it("decreases a path by removing the deepest split", function()
		assert.are.same({}, layout.decrease_path({}))
		assert.are.same({}, layout.decrease_path({ 1 }))
		assert.are.same({ 1 }, layout.decrease_path({ 1, 2 }))
	end)

	it("reports the depth of a path", function()
		assert.are.equal(0, layout.depth_for_path({}))
		assert.are.equal(2, layout.depth_for_path({ 1, 2 }))
	end)
end)

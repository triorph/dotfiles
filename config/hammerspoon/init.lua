hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()


local move_screen = function()
    print("Moving window")
    local window = hs.window.frontmostWindow()
    local next = window:screen():next()
    window:moveToScreen(next)
end

hs.hotkey.bind({"ctrl", "alt"}, "m", move_screen)

require("toggle_window")
require("newwp")

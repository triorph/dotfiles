function toggle_window(opts, key, name, unit)
    if unit == nil then
        unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
    end
    hs.hotkey.bind(opts, key, function()
        local app = hs.application.get(name)
        local screen = hs.screen.mainScreen()
        if app then
            if not app:mainWindow() then
                app = hs.application.open(name, 2.0, true)
            elseif app:isFrontmost() then
                app:hide()
            elseif app:isHidden() then
                if not (app:mainWindow():screen() == screen) then
                    app:mainWindow():moveToScreen(screen)
                end

                app:activate()
            else
                app:activate()
            end
        else
            app = hs.application.open(name, 2.0, true)
        end
        app:mainWindow():moveToUnit(unit)
        app:mainWindow():setShadows(false)
    end)
end

local move_screen = function()
	print("Moving window")
    local window = hs.window.frontmostWindow()
    local next = window:screen():next()
	window:moveToScreen(next)
end

toggle_window({ "ctrl" }, "`", "kitty")
-- toggle_window({"ctrl"}, "tab", "emacs")
toggle_window({ "ctrl" }, "tab", "Google Chrome")
toggle_window({ "ctrl", "alt" }, "s", "Spotify", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl"  }, "s", "Slack", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl", "alt" }, "z", "zoom.us")
hs.hotkey.bind({"ctrl", "alt"}, "m", move_screen)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

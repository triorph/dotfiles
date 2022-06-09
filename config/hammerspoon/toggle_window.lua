local toggle_window = function(opts, key, name, unit)
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
			else
				app:activate()
			end
		else
			app = hs.application.open(name, 2.0, true)
		end
		app:mainWindow():moveToUnit(unit)
	end)
end

toggle_window({ "ctrl" }, "`", "kitty")
toggle_window({ "ctrl" }, "tab", "Google Chrome")
toggle_window({ "ctrl", "alt" }, "s", "Spotify", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl" }, "s", "Slack", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl", "alt" }, "z", "zoom.us")
toggle_window({ "ctrl", "alt" }, "tab", "Emacs", { x = 0.45, y = 0.01, w = 0.5, h = 0.99 })

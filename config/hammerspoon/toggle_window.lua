local virtual_screens = require("virtual_screens")
local toggle_window = function(opts, key, name, unit, launcher_name)
	if unit == nil then
		unit = { x = 0.02, y = 0.02, w = 0.96, h = 0.96 }
	end
	if launcher_name == nil then
		launcher_name = name
	end
	hs.hotkey.bind(opts, key, function()
		local app = hs.application.get(name)
		local screen = hs.screen.mainScreen()
		if app then
			if not app:mainWindow() then
				app = hs.application.open(launcher_name, 2.0, true)
			elseif app:isFrontmost() then
				app:hide()
			else
				app:activate()
			end
		else
			app = hs.application.open(launcher_name, 2.0, true)
		end
		if app:focusedWindow() then
			virtual_screens.move_to_virtual_screen(app:focusedWindow(), nil, unit)
		else
			print("Error, app did not have a mainWindow at any point")
		end
	end)
end

print(hs.host.localizedName())
if hs.host.localizedName() == "CJDPHHJW5Q" then -- work laptop uses Chrome
	toggle_window({ "ctrl" }, "tab", "chrome")
	toggle_window({ "ctrl", "alt" }, "d", "IntelliJ IDEA", nil, "IntelliJ IDEA Ultimate")
elseif hs.host.localizedName() == "Michael’s MacBook Pro" then -- home laptop with firefox
	toggle_window({ "ctrl" }, "tab", "Firefox")
	-- so glad to be rid of teams
	-- toggle_window({ "ctrl", "alt" }, "z", "Microsoft Teams (work or school)", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
	toggle_window({ "ctrl", "alt" }, "d", "Parsec", nil, "Parsec")
	toggle_window({ "ctrl", "alt" }, "k", "Messages", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
	toggle_window({ "ctrl" }, "m", "Mail", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
end

toggle_window({ "ctrl" }, "`", "kitty")
toggle_window({ "ctrl", "alt" }, "s", "Spotify", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl" }, "s", "Slack", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl", "alt" }, "z", "zoom.us")
toggle_window({ "ctrl", "alt" }, "tab", "Emacs", { x = 0.01, y = 0.01, w = 0.49, h = 0.99 })
toggle_window({ "ctrl", "alt" }, "c", "hammerspoon", { x = 0.2, y = 0.2, w = 0.5, h = 0.5 }) -- hammerspoon console

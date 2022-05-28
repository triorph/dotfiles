function toggle_window(opts, key, name)
	hs.hotkey.bind(opts, key, function()
		local app = hs.application.get(name)
		local screen = hs.screen.mainScreen()
		if app then
			if not app:mainWindow() then
				app = hs.application.open(name, 2.0, true)
			elseif app:isFrontmost() then
				app:hide()
			else
				if not (app:mainWindow().screen == screen) then
					app:mainWindow():moveToScreen(screen)
				end

				app:activate()
			end
		else
			app = hs.application.open(name, 2.0, true)
		end
		-- app:mainWindow():moveToUnit("[100,100,0,0]")
		-- app:mainWindow().setShadows(false)
	end)
end

toggle_window({ "ctrl" }, "`", "kitty")
-- toggle_window({"ctrl"}, "tab", "emacs")
toggle_window({ "ctrl" }, "tab", "Google Chrome")

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

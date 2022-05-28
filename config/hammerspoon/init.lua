hs.hotkey.bind({ "ctrl" }, "`", function()
	local app = hs.application.get("kitty")
	print(app:name())
	local screen = hs.screen.mainScreen()
	if app then
		if not app:mainWindow() then
			app = hs.application.open("kitty", 2.0, true)
		elseif app:isFrontmost() then
			app:hide()
		else
			if not (app:mainWindow().screen == screen) then
				app:mainWindow():moveToScreen(screen)
			end

			app:activate()
		end
	else
		app = hs.application.open("kitty", 2.0, true)
	end
	app:mainWindow():moveToUnit("[100,100,0,0]")
	-- app:mainWindow().setShadows(false)
end)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

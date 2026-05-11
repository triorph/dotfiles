local debug_log = require("debug_log")
local virtual_screens = require("virtual_screens")

local window_config_for = function(window_config)
	if window_config == nil then
		return { mode = "fixed" }
	end
	if window_config.mode ~= nil then
		return window_config
	end
	return {
		mode = "floating",
		floating_unit = window_config,
	}
end

local toggle_window = function(opts, key, name, window_config, launcher_name)
	if launcher_name == nil then
		-- usually launcher is the same as the app
		launcher_name = name
	end
	hs.hotkey.bind(opts, key, function()
		local app = hs.application.get(name)
		if app and app:mainWindow() then
			-- toggle the window for existing apps
			if app:isFrontmost() then
				-- hide app
				if app:name() == "Arc" then
					app:selectMenuItem("Hide Arc")
				else
					app:hide()
				end
			else
				-- make app active
				app:activate()
			end
		else
			-- launch app if doesn't exist
			app = hs.application.open(launcher_name, 2.0, true)
		end
		-- set app size and position
		if app:focusedWindow() then
			local window = app:focusedWindow()
			if not virtual_screens.has_window_state(window) then
				virtual_screens.configure_window(window, window_config_for(window_config))
			end
			virtual_screens.reapply_window(window)
		else
			-- this usually means a setup error - probably hammerspoon doesn't
			-- have privacy permissions added
			debug_log.log("Error, app did not have a mainWindow at any point")
		end
	end)
end

debug_log.log(hs.host.localizedName())
if hs.host.localizedName() == "CJDPHHJW5Q" then -- work laptop
	toggle_window({ "ctrl", "alt" }, "d", "IntelliJ IDEA", nil, "IntelliJ IDEA Ultimate")
	toggle_window({ "ctrl", "alt" }, "g", "Goland", nil, "Goland")
	-- toggle_window({ "ctrl", "alt", "cmd" }, "d", "Cursor")
	toggle_window({ "ctrl" }, "tab", "Arc")
elseif hs.host.localizedName() == "Michael’s MacBook Pro" then -- home laptop
	-- so glad to be rid of teams
	-- toggle_window({ "ctrl", "alt" }, "z", "Microsoft Teams (work or school)", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
	-- toggle_window({ "ctrl", "alt" }, "d", "Parsec", nil, "Parsec")
	toggle_window({ "ctrl", "alt" }, "k", "Messages", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
	toggle_window({ "ctrl" }, "tab", "Firefox")
end

toggle_window({ "ctrl" }, "`", "kitty")
toggle_window({ "ctrl", "alt" }, "s", "Spotify", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl" }, "s", "Slack", { x = 0.1, y = 0.1, w = 0.8, h = 0.8 })
toggle_window({ "ctrl", "alt" }, "z", "zoom.us")
-- notes app
toggle_window({ "ctrl", "alt" }, "tab", "Emacs", { mode = "fixed", default_path = { 1 } })
-- hammerspoon console
toggle_window({ "ctrl", "alt" }, "c", "hammerspoon", { x = 0.2, y = 0.2, w = 0.5, h = 0.5 })

local debug_log = require("debug_log")
local virtual_screens = require("virtual_screens")
math.randomseed(os.time())

local config_path = "~/.config/wallhaven.json"

local call_url = function(page)
	local config = hs.json.read(config_path)
	if config == nil then
		debug_log.log("Wallpaper config missing at", config_path)
		return nil
	end

	local username = config.username
	local collection_id = config.collection_id
	local api_key = config.api_key
	if username == nil or collection_id == nil or api_key == nil then
		debug_log.log("Wallpaper config is missing username, collection_id, or api_key")
		return nil
	end

	local url = "https://wallhaven.cc/api/v1/collections/"
		.. username
		.. "/"
		.. collection_id
		.. "/?apikey="
		.. api_key
		.. "&page="
		.. page
	local status, body, _headers = hs.http.get(url)
	if status ~= 200 or body == nil then
		debug_log.log("Wallpaper API request failed", status, url)
		return nil
	end
	return hs.json.decode(body)
end

local check_file_exists = function(filepath)
	local this_file = io.open(filepath, "r")
	if this_file then
		this_file:close()
		return true
	end
	return false
end

local download_from_url = function(url, filepath)
	debug_log.log("Writing url ", url, "to file", filepath)
	if check_file_exists(filepath) then
		debug_log.log("Skipping download as file already exists on disk")
		return true
	end

	local status, body, _headers = hs.http.get(url)
	if status ~= 200 or body == nil then
		debug_log.log("Wallpaper image download failed", status, url)
		return false
	end

	local this_file, open_error = io.open(filepath, "w")
	if this_file then
		this_file:write(body)
		this_file:close()
		return true
	end

	debug_log.log("error opening file", open_error)
	return false
end

local get_screen_by_index = function(index)
	for i, screen in ipairs(hs.screen.allScreens()) do
		debug_log.log("Checking screen", i, index, screen)
		if i == index then
			debug_log.log("Found screen")
			return screen
		end
	end
	debug_log.log("No screen found for index", index)
	return nil
end

local newwp
newwp = function(index, screen)
	if screen == nil then
		for _, screen_for_wallpaper in ipairs(hs.screen.allScreens()) do
			newwp(index, screen_for_wallpaper)
		end
		return
	end
	if type(screen) == "number" then
		screen = get_screen_by_index(screen)
	end
	if screen == nil then
		return
	end
	debug_log.log("Screen is:", screen)

	local collection = call_url(0)
	if collection == nil or collection.meta == nil then
		return
	end
	local meta = collection.meta
	local per_page = meta.per_page
	local total = meta.total
	if per_page == nil or total == nil or total == 0 then
		debug_log.log("Wallpaper collection metadata is missing or empty")
		return
	end
	if index == nil then
		index = math.floor(math.random() * total)
		debug_log.log("index chosen is", index)
	end
	local page = math.floor(index / per_page)
	local new_index = index % per_page + 1
	local page_data = call_url(page)
	if page_data == nil or page_data.data == nil or page_data.data[new_index] == nil then
		debug_log.log("Wallpaper data missing for index", index)
		return
	end
	local desktop_url = page_data.data[new_index].path
	if desktop_url == nil then
		debug_log.log("Wallpaper data missing path for index", index)
		return
	end
	local filepath = os.getenv("HOME") .. "/.wallpapers/" .. desktop_url:match("^.+/(.+)$")
	if download_from_url(desktop_url, filepath) then
		screen:desktopImageURL("file://" .. filepath)
	end
end

local newwp_for_active_window_screen = function(index)
	local window = hs.window.frontmostWindow()
	if window == nil then
		debug_log.log("No frontmost window")
		return
	end

	local screen = virtual_screens.get_physical_screen_for_window(window) or window:screen()
	if screen ~= nil then
		newwp(index, screen)
	end
end

hs.hotkey.bind({ "ctrl", "cmd", "alt" }, "w", newwp)
hs.hotkey.bind({ "ctrl", "alt" }, "w", newwp_for_active_window_screen)

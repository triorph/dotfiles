local debug_log = require("debug_log")
math.randomseed(os.time())
local call_url = function(page)
	local config = hs.json.read("~/.config/wallhaven.json")
	local username = config.username
	local collection_id = config.collection_id
	local api_key = config.api_key

	local url = "https://wallhaven.cc/api/v1/collections/"
		.. username
		.. "/"
		.. collection_id
		.. "/?apikey="
		.. api_key
		.. "&page="
		.. page
	local status, body, headers = hs.http.get(url)
	local json = hs.json.decode(body)
	return json
end
local check_file_exists = function(filepath)
	local this_file, error = io.open(filepath, "r")
	if this_file then
		this_file:close()
		return true
	else
		return false
	end
end
local download_from_url = function(url, filepath)
	debug_log.log("Writing url ", url, "to file", filepath)
	if not check_file_exists(filepath) then
		local _status, body, _headers = hs.http.get(url)
		local this_file, error = io.open(filepath, "w")
		if this_file then
			this_file:write(body)
			this_file:close()
		else
			debug_log.log("error opening file", error)
		end
	else
		debug_log.log("Skipping download as file already exists on disk")
	end
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

function newwp(index, screen)
	if screen == nil then
		for _, screen in ipairs(hs.screen.allScreens()) do
			newwp(index, screen)
		end
		return
	end
	if type(screen) == "number" then
		screen = get_screen_by_index(screen)
	end
	debug_log.log("Screen is:", screen)

	local meta = call_url(0).meta
	local per_page = meta.per_page
	local total = meta.total
	if index == nil then
		index = math.floor(math.random() * total)
		debug_log.log("index chosen is", index)
	end
	local page = math.floor(index / per_page)
	local new_index = index % per_page + 1
	local data = call_url(page).data
	local desktop_url = data[new_index].path
	local filepath = os.getenv("HOME") .. "/.wallpapers/" .. desktop_url:match("^.+/(.+)$")
	download_from_url(desktop_url, filepath)
	screen:desktopImageURL("file://" .. filepath)
end

hs.hotkey.bind({ "ctrl", "cmd", "alt" }, "w", newwp)

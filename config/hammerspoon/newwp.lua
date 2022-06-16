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
	print("Writing url ", url, "to file", filepath)
	if not check_file_exists(filepath) then
		local _status, body, _headers = hs.http.get(url)
		local this_file, error = io.open(filepath, "w")
		if this_file then
			this_file:write(body)
			this_file:close()
		else
			print("error opening file", error)
		end
	else
		print("Skipping download as file already exists on disk")
	end
end

function newwp(index, screen)
	if screen == nil then
		for _, screen in ipairs(hs.screen.allScreens()) do
			newwp(index, screen)
		end
		return
	end
	local meta = call_url(0).meta
	local per_page = meta.per_page
	local total = meta.total
	if index == nil then
		index = math.floor(math.random() * total)
		print("index chosen is", index)
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

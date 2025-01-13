local headphones_id = "88-c9-e8-37-35-61"
local earbuds_id = "f8-4e-17-ee-97-9f"
local airpods_id = "b0-f1-d8-ac-3f-ba"

local blueutil_command = function(args)
	local t = hs.task.new("/opt/homebrew/bin/blueutil", nil, args)
	t:start()
end

local bluetooth_power = function(power)
	print("Setting bluetooth power to " .. power)
	blueutil_command({ "--power", power })
end

local connect_headphones = function()
	print("Connecting headphones")
	blueutil_command({ "--connect", headphones_id })
end

local disconnect_headphones = function()
	print("Disconnecting headphones")
	blueutil_command({ "--disconnect", headphones_id, "--wait-disconnect", headphones_id })
end

local disconnect_earbuds = function()
	print("Disconnecting earbuds")
	blueutil_command({ "--disconnect", earbuds_id, "--wait-disconnect", earbuds_id })
end

local connect_earbuds = function()
	print("Connecting earbuds")
	blueutil_command({ "--connect", earbuds_id })
end

local connect_airpods = function()
	print("Connecting airpods")
	blueutil_command({ "--connect", airpods_id })
end

local disconnect_airpods = function()
	print("Disconnecting airpods")
	blueutil_command({ "--disconnect", airpods_id, "--wait-disconnect", airpods_id })
end

local bluetooth_watcher = function(event)
	if event == hs.caffeinate.watcher.systemWillSleep then
		bluetooth_power("off")
	elseif event == hs.caffeinate.watcher.screensDidWake then
		bluetooth_power("on")
	end
end

local turn_on_bluetooth_power = function()
	bluetooth_power("on")
end

watcher = hs.caffeinate.watcher.new(bluetooth_watcher)
watcher:start()

hs.hotkey.bind({ "ctrl", "alt" }, "h", connect_headphones)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "h", disconnect_headphones)
hs.hotkey.bind({ "ctrl", "alt" }, "e", connect_earbuds)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "e", disconnect_earbuds)
hs.hotkey.bind({ "ctrl", "alt" }, "a", connect_airpods)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "a", disconnect_airpods)
hs.hotkey.bind({ "ctrl", "alt" }, "p", turn_on_bluetooth_power)

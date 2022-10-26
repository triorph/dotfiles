local headphones_id = "88-c9-e8-37-35-61"
local blueutil_command = function(args)
	local t = hs.task.new("/opt/homebrew/bin/blueutil", nil, args)
	t:start()
end

local bluetooth_power = function(power)
	blueutil_command({ "--power", power })
end

local connect_headphones = function()
	blueutil_command({ "--connect", headphones_id })
end

local disconnect_headphones = function()
	print("Disconnecting headphones")
	blueutil_command({ "--disconnect", headphones_id, "--wait-disconnect", headphones_id })
end

local bluetooth_watcher = function(event)
	if event == hs.caffeinate.watcher.systemWillSleep then
		disconnect_headphones()
	elseif event == hs.caffeinate.watcher.screensDidWake then
		bluetooth_power("on")
	end
end

watcher = hs.caffeinate.watcher.new(bluetooth_watcher)
watcher:start()

hs.hotkey.bind({ "ctrl", "alt" }, "h", connect_headphones)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "h", disconnect_headphones)

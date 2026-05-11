local debug_log = require("debug_log")
-- midi.lua
-- Specifies controls for the MVAVE chocolate bluetooth midi controller
--
-- Originally I intended to have devices hook in to the midi inputs directly,
-- but that doesn't seem to work with GarageBand and other apps are paid
-- and confusing - or don't do everything I want (mostly just good ampsims
-- such as Neural Amp Modeler and the ability to do loops).
--
-- Neural DSP seemed good on Midi inputs, but doesn't allow looping
-- (and GarageBand doesn't allow the midi to work when using NeuralDSP as
-- a plugin). I think Reaper might've been alright but I found it too confusing
-- to setup loops. LoopyPro looked promising but is only available on iOS
--
-- Given that all of these cost money, I'm pretty happy with this solution below
--
-- One problem I had with the MVAVE chocolate configured for keypad inputs
-- on its own, is that it kept sending double inputs. I'm not sure why it
-- does this, but I've setup a debounce timer so that if it receives 2
-- messages within 250ms it doesn't send the 2nd one (unfortunately its
-- quite easy to press the button faster than this, but c'est la vie)

-- A timer to prevent multiple keys being sent in a row
LastTime = hs.timer.absoluteTime()

-- I've programmed all 8 buttons to send on channel 0 with
-- programNumber 1 through 8
--
-- 1-4 are regular pressed, 5-8 are long-presses of the same buttons
local function sendKeysToGarageBand(garageBandApp, programNumber)
	if programNumber == 1 then
		-- send Up to change track being used
		hs.eventtap.keyStroke(nil, "up", nil, garageBandApp)
	end
	if programNumber == 2 then
		-- send down to change track being used
		hs.eventtap.keyStroke(nil, "down", nil, garageBandApp)
	end
	if programNumber == 3 then
		-- send r to toggle recording
		hs.eventtap.keyStroke(nil, "r", nil, garageBandApp)
	end
	if programNumber == 4 then
		-- send space to toggle playing (or stop recording)
		hs.eventtap.keyStroke(nil, "space", nil, garageBandApp)
	end
	if programNumber == 5 then
		-- send right to select tracks (usually to delete)
		hs.eventtap.keyStroke(nil, "right", nil, garageBandApp)
	end
	if programNumber == 6 then
		-- send delete to delete selected tracks
		hs.eventtap.keyStroke(nil, "delete", nil, garageBandApp)
	end
	if programNumber == 7 then
		-- send cmd+z to undo changes
		hs.eventtap.keyStroke({ "cmd" }, "z", nil, garageBandApp)
	end
	if programNumber == 8 then
		-- send m to mute track
		hs.eventtap.keyStroke(nil, "m", nil, garageBandApp)
	end
end

-- Define callback for MIDI events
local function handleMIDI(object, deviceName, commandType, description, metadata)
	local currentTime = hs.timer.absoluteTime()
	local debounceDelay = 250 * 1000 * 1000 -- 250 ms
	local app = hs.application.get("GarageBand")
	if
		-- Don't send double-taps from the foot controller
		currentTime - LastTime > debounceDelay
		-- only trigger on FootCtrl defined events
		and (deviceName == "FootCtrl" and commandType == "programChange" and metadata.channel == 0)
		-- only send to GarageBand if it's open
		and (app and app:mainWindow())
	then
		sendKeysToGarageBand(app, metadata.programNumber)
	end
	LastTime = currentTime
end

-- Define callback to register the FootCtrl device
local function registerDevices(devices, _virtualDevices)
	for _i, device in pairs(devices) do
		if device == "FootCtrl" then
			debug_log.log("Adding callback on device " .. device)
			midiDevice = hs.midi.new(device)
			midiDevice:callback(handleMIDI)
		end
	end
end

-- Subscribe to registration
hs.midi.deviceCallback(registerDevices)

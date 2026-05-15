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

local debounce_delay = 250 * 1000 * 1000 -- 250 ms
local last_time = hs.timer.absoluteTime()
local midi_devices = {}

-- I've programmed all 8 buttons to send on channel 0 with
-- programNumber 1 through 8
--
-- 1-4 are regular pressed, 5-8 are long-presses of the same buttons
local program_actions = {
	[1] = { modifiers = nil, key = "up" },
	[2] = { modifiers = nil, key = "down" },
	[3] = { modifiers = nil, key = "r" },
	[4] = { modifiers = nil, key = "space" },
	[5] = { modifiers = nil, key = "right" },
	[6] = { modifiers = { "cmd" }, key = "x" },
	[7] = { modifiers = { "cmd" }, key = "z" },
	[8] = { modifiers = nil, key = "m" },
}

local function send_keys_to_garage_band(garage_band_app, program_number)
	local action = program_actions[program_number]
	if action == nil then
		return
	end
	hs.eventtap.keyStroke(action.modifiers, action.key, nil, garage_band_app)
end

-- Define callback for MIDI events
local function handle_midi(_object, device_name, command_type, _description, metadata)
	local current_time = hs.timer.absoluteTime()
	local app = hs.application.get("GarageBand")
	if
		-- Don't send double-taps from the foot controller
		current_time - last_time > debounce_delay
		-- only trigger on FootCtrl defined events
		and (device_name == "FootCtrl" and command_type == "programChange" and metadata.channel == 0)
		-- only send to GarageBand if it's open
		and (app and app:mainWindow())
	then
		send_keys_to_garage_band(app, metadata.programNumber)
	end
	last_time = current_time
end

-- Define callback to register the FootCtrl device
local function register_devices(devices, _virtual_devices)
	for _i, device in pairs(devices) do
		if device == "FootCtrl" then
			debug_log.log("Adding callback on device " .. device)
			midi_devices[device] = hs.midi.new(device)
			midi_devices[device]:callback(handle_midi)
		end
	end
end

-- Subscribe to registration
hs.midi.deviceCallback(register_devices)

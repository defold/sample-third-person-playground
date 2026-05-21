local M = {}

-- URLs for sound components
M.BALL_CONTACT = "/audio#ball_contact"
M.BARREL_CONTACT = "/audio#barrel_contact"
M.DROP_ITEM = "/audio#drop_item"
M.PICK_UP_ITEM = "/audio#pick_up_item"
M.POSITIVE_FEEDBACK = "/audio#positive_feedback"
M.THROW_ITEM = "/audio#throw_item"
M.FOOTSTEPS = {
	"/audio#walking_1",
	"/audio#walking_2",
	"/audio#walking_3",
	"/audio#walking_4",
}

-- A table with booleans for sound gating
M.SOUND_GATES = {}

-- Helper function for generating a random speed from a range
local function random_speed(min_speed, max_speed)
	return min_speed + math.random() * (max_speed - min_speed)
end

---@param url string URL of the sound component to play
---@param gain? number Gain (volume) of the sound
---@param speed? number Speed of the sound
---@return number identifier for the sound
function M.play(url, gain, speed)
	return sound.play(url, { gain = gain, speed = speed })
end

---@param url string URL of the sound component to play
function M.stop(url)
	sound.stop(url)
end

--- Play a random sound from a list
---@param urls table<string> URLs of the sound components to play
---@param gain? number Gain (volume) of the sound
---@param min_speed? number Minimum speed of the sound
---@param max_speed? number Maximum speed of the sound
---@return string, nil
function M.play_random(urls, gain, min_speed, max_speed)
	local url = urls[math.random(#urls)]
	return url, M.play(url, gain, random_speed(min_speed or 1.0, max_speed or 1.0))
end

--- Play a sound with gating to prevent overlap
---@param key string Unique key for the gating
---@param url string URL of the sound component to play
---@param cooldown number Time in seconds before the sound can be played again
---@param gain? number Gain (volume) of the sound
---@param speed? number Speed of the sound
---@return boolean True if sound is played, false if gated
function M.play_gated(key, url, cooldown, gain, speed)
	if M.SOUND_GATES[key] then
		return false
	end

	M.SOUND_GATES[key] = true
	M.play(url, gain, speed)
	timer.delay(cooldown, false, function()
		M.SOUND_GATES[key] = nil
	end)
	return true
end

return M

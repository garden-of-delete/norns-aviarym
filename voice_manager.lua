-- Voice Manager Module
-- Handles voice state and operations

local VoiceManager = {}

-- Voice state
local voice_count = nil
local voice_playing = {}
local voice_current_sample = {}
local voice_position = {}
local selected_voice = 1
local volume = nil

function VoiceManager.init(sample_files, sample_slices, cartographer_instance, config)
  -- Initialize config values
  voice_count = config.VOICE_COUNT
  volume = config.DEFAULT_VOLUME
  
  -- Initialize voice state
  for i = 1, voice_count do
    voice_playing[i] = false
    voice_current_sample[i] = ((i - 1) % #sample_files) + 1  -- Distribute samples across voices
    voice_position[i] = 0
  end
  
  -- Set up all voices with cartographer
  print("\nSetting up voices...")
  for i = 1, voice_count do
    local sample_index = voice_current_sample[i]
    
    -- Assign voice to its slice
    if sample_index <= #sample_slices then
      cartographer_instance.assign(sample_slices[sample_index], i)
      print("Voice " .. i .. " assigned to slice " .. sample_index .. " (" .. sample_files[sample_index] .. ")")
    else
      -- If we have more voices than slices, assign to existing slices
      local slice_index = ((sample_index - 1) % #sample_slices) + 1
      cartographer_instance.assign(sample_slices[slice_index], i)
      print("Voice " .. i .. " assigned to slice " .. slice_index .. " (shared)")
    end
    
    -- Configure voice
    softcut.enable(i, 1)
    softcut.level(i, volume)
    softcut.loop(i, 1)
    softcut.rate(i, 1.0)
    softcut.pan(i, util.linlin(1, voice_count, -1, 1, i))  -- Spread across stereo field
    softcut.play(i, 0)  -- Start stopped
  end
end

function VoiceManager.toggle_voice(voice_num, sample_slices)
  if voice_num < 1 or voice_num > voice_count then
    print("Invalid voice number: " .. voice_num)
    return
  end
  
  voice_playing[voice_num] = not voice_playing[voice_num]
  softcut.play(voice_num, voice_playing[voice_num] and 1 or 0)
  
  if voice_playing[voice_num] then
    -- Reset position to start when starting playback
    local slice = sample_slices[voice_current_sample[voice_num]]
    if slice then
      slice:trigger(voice_num)
      voice_position[voice_num] = 0
    end
  end
  
  print("Voice " .. voice_num .. " play state: " .. (voice_playing[voice_num] and "ON" or "OFF"))
end

function VoiceManager.toggle_all_voices(sample_slices)
  -- Check if any voices are playing
  local any_playing = false
  for i = 1, voice_count do
    if voice_playing[i] then
      any_playing = true
      break
    end
  end
  
  if any_playing then
    -- Stop all voices
    for i = 1, voice_count do
      voice_playing[i] = false
      softcut.play(i, 0)
    end
    print("All voices stopped")
  else
    -- Start all voices
    for i = 1, voice_count do
      voice_playing[i] = true
      softcut.play(i, 1)
      
      -- Reset positions
      local sample_index = voice_current_sample[i]
      if sample_index <= #sample_slices then
        local slice = sample_slices[sample_index]
        slice:trigger(i)
        voice_position[i] = 0
      end
    end
    print("All voices started")
  end
end

function VoiceManager.set_volume(new_volume)
  volume = util.clamp(new_volume, 0, 1)
  for i = 1, voice_count do
    softcut.level(i, volume)
  end
  print("Volume: " .. string.format("%.2f", volume))
end

function VoiceManager.set_selected_voice(voice_num)
  selected_voice = util.clamp(voice_num, 1, voice_count)
  print("Selected voice: " .. selected_voice)
end

function VoiceManager.set_voice_position(voice_num, position, sample_slices)
  local sample_index = voice_current_sample[voice_num]
  if sample_index <= #sample_slices then
    voice_position[voice_num] = util.clamp(position, 0, 1)
    
    local slice = sample_slices[sample_index]
    slice:position(voice_num, voice_position[voice_num], 'fraction')
    
    print("Voice " .. voice_num .. " position: " .. string.format("%.2f", voice_position[voice_num]))
  end
end

-- Getters
function VoiceManager.get_voice_count() return voice_count end
function VoiceManager.get_voice_playing() return voice_playing end
function VoiceManager.get_voice_current_sample() return voice_current_sample end
function VoiceManager.get_voice_position() return voice_position end
function VoiceManager.get_selected_voice() return selected_voice end
function VoiceManager.get_volume() return volume end

return VoiceManager 
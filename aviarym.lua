-- aviarym
-- minimal sample player using cartographer for buffer management
--
-- KEY 2 toggle voice playback
-- KEY 3 toggle all voices
-- ENC 1 change volume for all voices
-- ENC 2 select voice
-- ENC 3 change sample position for selected voice

local Setup = dofile('/home/we/dust/code/aviarym/setup.lua')

-- Try to load cartographer with error handling
local cartographer = nil
local cartographer_available = false

local function load_cartographer()
  local success, result = pcall(function()
    return include('lib/cartographer/cartographer')
  end)
  
  if success and result then
    cartographer = result
    cartographer_available = true
    print("Cartographer loaded successfully!")
    return true
  else
    print("Error loading cartographer: " .. tostring(result))
    print("Please ensure cartographer is installed in /home/we/dust/code/lib/cartographer/")
    print("Run the setup again or install manually from:")
    print("https://github.com/andr-ew/cartographer")
    return false
  end
end

-- Load cartographer
if not load_cartographer() then
  print("Cannot continue without cartographer dependency")
  return
end

-- Voice and sample management
local voice_count = 6
local voice_playing = {}
local voice_current_sample = {}
local voice_position = {}
local selected_voice = 1
local volume = 1.0

-- Cartographer slices
local sample_slices = {}
local sample_files = {}

-- Function to read metadata file
local function read_metadata()
  local file = io.open("/home/we/dust/data/aviarym/samples.json", "r")
  if not file then
    print("Error: Could not open metadata file")
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Simple JSON parsing for our specific format
  local samples = {}
  for line in content:gmatch('"([^"]+)"') do
    if line:match("%.wav$") then  -- Only include WAV files
      table.insert(samples, line)
    end
  end
  
  if #samples == 0 then
    print("No samples found in metadata file")
    return nil
  end
  
  return samples
end

function init()
  Setup.init()
  
  -- Debug print Setup table values
  print("Setup table values:")
  for key, value in pairs(Setup) do
    print(string.format("  %s: %s", key, tostring(value)))
    if type(value) == "boolean" and not value then
      print("ERROR: Setup failed - " .. key .. " is false")
      return
    end
  end
  
  -- Initialize random seed
  math.randomseed(os.time())
  
  -- Read metadata and get available samples
  local samples = read_metadata()
  if not samples then
    print("No samples available")
    return
  end
  
  sample_files = samples
  print("Found " .. #sample_files .. " samples")
  
  -- Initialize voice state
  for i = 1, voice_count do
    voice_playing[i] = false
    voice_current_sample[i] = ((i - 1) % #sample_files) + 1  -- Distribute samples across voices
    voice_position[i] = 0
  end
  
  -- Clear buffers
  print("\nClearing buffers...")
  softcut.buffer_clear()
  
  -- Create slices for samples using cartographer
  print("Setting up cartographer slices...")
  
  -- Divide buffer 1 into slices for our samples
  -- We'll use both buffers to maximize available space
  local buffer1_slices = cartographer.divide(cartographer.buffer[1], math.min(#sample_files, 3))
  local buffer2_slices = cartographer.divide(cartographer.buffer[2], math.min(#sample_files - 3, 3))
  
  -- Combine slices from both buffers
  sample_slices = {}
  for i = 1, math.min(#sample_files, 3) do
    sample_slices[i] = buffer1_slices[i]
  end
  for i = 1, math.min(#sample_files - 3, 3) do
    sample_slices[i + 3] = buffer2_slices[i]
  end
  
  print("Created " .. #sample_slices .. " slices")
  
  -- Load samples into slices
  print("Loading samples into slices...")
  for i = 1, math.min(#sample_files, #sample_slices) do
    local sample_file = sample_files[i]
    print("Loading sample " .. i .. ": " .. sample_file)
    
    -- Load file into slice, setting slice length to match sample
    sample_slices[i]:read(sample_file, 0, 1, 'source')
    
    print("  Loaded into slice " .. i)
  end
  
  -- Set up all 6 voices with cartographer
  print("\nSetting up voices...")
  for i = 1, voice_count do
    local sample_index = voice_current_sample[i]
    
    -- Assign voice to its slice
    if sample_index <= #sample_slices then
      cartographer.assign(sample_slices[sample_index], i)
      print("Voice " .. i .. " assigned to slice " .. sample_index .. " (" .. sample_files[sample_index] .. ")")
    else
      -- If we have more voices than slices, assign to existing slices
      local slice_index = ((sample_index - 1) % #sample_slices) + 1
      cartographer.assign(sample_slices[slice_index], i)
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
  
  -- Audio routing setup
  print("\nSetting up audio routing:")
  audio.level_adc_cut(1.0)
  audio.level_eng_cut(1.0)
  audio.level_tape_cut(1.0)
  print("Audio routing configured")
  
  print("\nInitialization complete")
  print("Press K2 to toggle selected voice, K3 to toggle all voices")
  print("Use E2 to select voice, E3 to change position")
  redraw()
end

function key(n,z)
  if z == 1 then  -- Key press
    if n == 2 then
      print("K2 pressed - toggling voice " .. selected_voice)
      
      -- Toggle the selected voice
      voice_playing[selected_voice] = not voice_playing[selected_voice]
      softcut.play(selected_voice, voice_playing[selected_voice] and 1 or 0)
      
      if voice_playing[selected_voice] then
        -- Reset position to start when starting playback
        local slice = sample_slices[voice_current_sample[selected_voice]]
        if slice then
          slice:trigger(selected_voice)
          voice_position[selected_voice] = 0
        end
      end
      
      print("Voice " .. selected_voice .. " play state: " .. (voice_playing[selected_voice] and "ON" or "OFF"))
      
    elseif n == 3 then
      print("K3 pressed - toggling ALL voices")
      
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
    
    redraw()
  end
end

function enc(n,d)
  if n == 1 then
    -- Master volume
    volume = util.clamp(volume + d * 0.01, 0, 1)
    for i = 1, voice_count do
      softcut.level(i, volume)
    end
    print("Volume: " .. string.format("%.2f", volume))
    
  elseif n == 2 then
    -- Voice selection
    selected_voice = util.clamp(selected_voice + d, 1, voice_count)
    print("Selected voice: " .. selected_voice)
    
  elseif n == 3 then
    -- Position control for selected voice
    local sample_index = voice_current_sample[selected_voice]
    if sample_index <= #sample_slices then
      voice_position[selected_voice] = util.clamp(voice_position[selected_voice] + d * 0.01, 0, 1)
      
      local slice = sample_slices[sample_index]
      slice:position(selected_voice, voice_position[selected_voice], 'fraction')
      
      print("Voice " .. selected_voice .. " position: " .. string.format("%.2f", voice_position[selected_voice]))
    end
  end
  
  redraw()
end

function redraw()
  screen.clear()
  
  -- Header
  screen.move(64, 10)
  screen.text_center("Aviarym - 6 Voice Sample Player")
  
  -- Voice status
  for i = 1, voice_count do
    local y = 20 + (i - 1) * 8
    screen.move(10, y)
    
    -- Highlight selected voice
    if i == selected_voice then
      screen.level(15)
      screen.text("> ")
    else
      screen.level(8)
      screen.text("  ")
    end
    
    -- Voice number and status
    screen.text("V" .. i .. ": ")
    
    if voice_playing[i] then
      screen.level(15)
      screen.text("ON  ")
    else
      screen.level(8)
      screen.text("OFF ")
    end
    
    -- Sample name (shortened)
    local sample_index = voice_current_sample[i]
    if sample_index <= #sample_files then
      local filename = sample_files[sample_index]
      local short_name = filename:match("([^/]+)%.wav$") or filename
      -- Truncate if too long
      if #short_name > 12 then
        short_name = short_name:sub(1, 9) .. "..."
      end
      screen.text(short_name)
    end
    
    -- Position for selected voice
    if i == selected_voice then
      screen.move(90, y)
      screen.text(string.format("%.2f", voice_position[i]))
    end
  end
  
  -- Controls
  screen.move(10, 78)
  screen.level(8)
  screen.text("E1: volume  E2: select voice  E3: position")
  screen.move(10, 88)
  screen.text("K2: toggle voice  K3: toggle all")
  screen.move(10, 98)
  screen.text("VOL: " .. string.format("%.2f", volume))
  
  screen.update()
end

-- aviarym
-- minimal sample player
--
-- KEY 2 toggle both voices simultaneously
-- ENC 2 change sample position for voice 1
-- ENC 3 change sample position for voice 2
-- ENC 1 change volume for both voices

local Setup = dofile('/home/we/dust/code/aviarym/setup.lua')

-- Table to store sample positions
local sample_positions = {}

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

-- Function to choose random sample index
local function choose_random_sample_index()
  if #sample_positions == 0 then
    print("Error: No samples loaded")
    return 1
  end
  return math.random(1, #sample_positions)
end

function init()
  Setup.init()
  
  -- Initialize variables
  volume = 1.0
  position1 = 0
  position2 = 0
  is_playing = false
  voice1_playing = false
  voice2_playing = false
  current_sample1 = 1  -- Start with first sample
  current_sample2 = 1  -- Start with first sample
  
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
  
  -- Store sample information (but don't load them yet)
  sample_positions = {}
  for i, sample_file in ipairs(samples) do
    local ch, samples_count, samplerate = audio.file_info(sample_file)
    local duration = samples_count / samplerate
    
    sample_positions[i] = {
      file = sample_file,
      duration = duration,
      channels = ch,
      sample_count = samples_count,
      sample_rate = samplerate
    }
    
    print(string.format("Sample %d: %s (%.2fs)", i, sample_file, duration))
  end
  
  -- Clear buffers
  print("\nClearing buffers...")
  softcut.buffer_clear()
  print("Buffers cleared")
  
  -- Set up voices (they'll load samples when first played)
  print("\nSetting up voices...")
  
  -- Voice 1 setup
  print("Setting up voice 1:")
  softcut.enable(1, 1)
  softcut.buffer(1, 1)
  softcut.level(1, volume)
  softcut.loop(1, 1)
  softcut.loop_start(1, 0)
  softcut.loop_end(1, 1)  -- Will be updated when sample loads
  softcut.position(1, 0)
  softcut.rate(1, 1.0)
  softcut.pan(1, -0.5)  -- Pan slightly left
  softcut.play(1, 0)  -- Start stopped
  
  -- Voice 2 setup  
  print("Setting up voice 2:")
  softcut.enable(2, 1)
  softcut.buffer(2, 2)  -- Use buffer 2 for voice 2
  softcut.level(2, volume)
  softcut.loop(2, 1)
  softcut.loop_start(2, 0)
  softcut.loop_end(2, 1)  -- Will be updated when sample loads
  softcut.position(2, 0)
  softcut.rate(2, 1.0)
  softcut.pan(2, 0.5)  -- Pan slightly right
  softcut.play(2, 0)  -- Start stopped
  
  -- Audio routing setup
  print("\nSetting up audio routing:")
  audio.level_adc_cut(1.0)
  audio.level_eng_cut(1.0)
  audio.level_tape_cut(1.0)
  print("Audio routing configured")
  
  -- Initialize state variables
  position1 = 0
  position2 = 0
  is_playing = false
  voice1_playing = false
  voice2_playing = false
  current_samples = samples
  voice1_loaded_sample = 0  -- Track which sample is loaded
  voice2_loaded_sample = 0
  
  print("\nInitialization complete")
  print("Press K2 to play voice 1, K3 to play voice 2")
  redraw()
end

-- Function to load a sample into a specific buffer
function load_sample_to_buffer(sample_index, buffer_num, voice_num)
  if sample_index < 1 or sample_index > #sample_positions then
    print("Error: Invalid sample index")
    return false
  end
  
  local sample_info = sample_positions[sample_index]
  print("Loading sample " .. sample_index .. " into buffer " .. buffer_num .. ": " .. sample_info.file)
  
  -- Clear the specific buffer
  if buffer_num == 1 then
    softcut.buffer_clear_region(1, 0, sample_info.duration + 1)
  else
    softcut.buffer_clear_region(2, 0, sample_info.duration + 1)
  end
  
  -- Load the sample
  softcut.buffer_read_mono(sample_info.file, 0, 0, -1, 1, buffer_num)
  
  -- Update voice parameters
  softcut.loop_start(voice_num, 0)
  softcut.loop_end(voice_num, sample_info.duration)
  softcut.position(voice_num, 0)
  
  print("Sample loaded - duration: " .. string.format("%.2f", sample_info.duration) .. "s")
  return true
end

function key(n,z)
  print("Key pressed: " .. n .. " state: " .. z)
  
  if n == 2 and z == 1 then
    print("K2 pressed - toggling voice 1")
    
    if not voice1_playing then
      -- Cycle to next sample for voice 1
      current_sample1 = current_sample1 + 1
      if current_sample1 > #sample_positions then
        current_sample1 = 1
      end
      
      -- Load the sample if it's not already loaded
      if voice1_loaded_sample ~= current_sample1 then
        print("Loading new sample for voice 1...")
        load_sample_to_buffer(current_sample1, 1, 1)
        voice1_loaded_sample = current_sample1
        -- Add a small delay to ensure loading completes
        clock.run(function()
          clock.sleep(0.1)
          position1 = 0  -- Reset normalized position
          redraw()
        end)
      end
    end
    
    -- Toggle play state
    voice1_playing = not voice1_playing
    softcut.play(1, voice1_playing and 1 or 0)
    print("Voice 1 play state: " .. (voice1_playing and "ON" or "OFF"))
    
  elseif n == 3 and z == 1 then
    print("K3 pressed - toggling voice 2")
    
    if not voice2_playing then
      -- Cycle to next sample for voice 2
      current_sample2 = current_sample2 + 1
      if current_sample2 > #sample_positions then
        current_sample2 = 1
      end
      
      -- Load the sample if it's not already loaded
      if voice2_loaded_sample ~= current_sample2 then
        print("Loading new sample for voice 2...")
        load_sample_to_buffer(current_sample2, 2, 2)
        voice2_loaded_sample = current_sample2
        -- Add a small delay to ensure loading completes
        clock.run(function()
          clock.sleep(0.1)
          position2 = 0  -- Reset normalized position
          redraw()
        end)
      end
    end
    
    -- Toggle play state
    voice2_playing = not voice2_playing
    softcut.play(2, voice2_playing and 1 or 0)
    print("Voice 2 play state: " .. (voice2_playing and "ON" or "OFF"))
  end
  
  -- Update global playing state
  is_playing = voice1_playing or voice2_playing
  redraw()
end

function enc(n,d)
  if n == 1 then
    volume = volume + (d * 0.1)
    if volume < 0 then volume = 0 end
    if volume > 1 then volume = 1 end
    softcut.level(1, volume)
    softcut.level(2, volume)
  elseif n == 2 then
    if voice1_loaded_sample > 0 then
      position1 = position1 + (d * 0.1)
      if position1 < 0 then position1 = 0 end
      if position1 > 1 then position1 = 1 end
      local sample_info = sample_positions[current_sample1]
      local new_pos = position1 * sample_info.duration
      softcut.position(1, new_pos)
    end
  elseif n == 3 then
    if voice2_loaded_sample > 0 then
      position2 = position2 + (d * 0.1)
      if position2 < 0 then position2 = 0 end
      if position2 > 1 then position2 = 1 end
      local sample_info = sample_positions[current_sample2]
      local new_pos = position2 * sample_info.duration
      softcut.position(2, new_pos)
    end
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.move(10, 20)
  screen.text("VOICE 1:")
  screen.move(10, 30)
  if voice1_loaded_sample > 0 then
    local sample_info = sample_positions[current_sample1]
    local actual_pos1 = position1 * sample_info.duration
    screen.text("POS: " .. string.format("%.2f", actual_pos1) .. "s")
    screen.move(10, 35)
    screen.text("Sample: " .. current_sample1)
  else
    screen.text("No sample loaded")
  end
  
  screen.move(10, 45)
  screen.text("VOICE 2:")
  screen.move(10, 55)
  if voice2_loaded_sample > 0 then
    local sample_info = sample_positions[current_sample2]
    local actual_pos2 = position2 * sample_info.duration
    screen.text("POS: " .. string.format("%.2f", actual_pos2) .. "s")
    screen.move(10, 60)
    screen.text("Sample: " .. current_sample2)
  else
    screen.text("No sample loaded")
  end
  
  screen.move(10, 70)
  screen.text("VOL: " .. string.format("%.2f", volume))
  screen.move(10, 80)
  screen.text("K2: toggle voice 1 (" .. (voice1_playing and "ON" or "OFF") .. ")")
  screen.move(10, 90)
  screen.text("K3: toggle voice 2 (" .. (voice2_playing and "ON" or "OFF") .. ")")
  screen.update()
end

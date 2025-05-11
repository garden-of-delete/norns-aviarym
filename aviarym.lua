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
  
  -- Initialize Softcut parameters
  softcut.buffer_clear()
  
  -- Load all samples sequentially into buffer 1
  local current_position = 0
  for i, sample_file in ipairs(samples) do
    print("Loading sample: " .. sample_file)
    local ch, samples, samplerate = audio.file_info(sample_file)
    local duration = samples / samplerate
    
    -- Store start and end positions for this sample
    sample_positions[i] = {
      start = current_position,
      end_pos = current_position + duration,
      file = sample_file
    }
    
    -- Read file into buffer 1 at current position
    softcut.buffer_read_mono(sample_file, current_position, 1, -1, 1, 1)
    current_position = current_position + duration
  end
  
  print("\n=== SAMPLE BUFFER INFORMATION ===")
  print("Total samples loaded: " .. #sample_positions)
  print("Total buffer duration: " .. string.format("%.2f", current_position) .. " seconds")
  print("\nDetailed sample information:")
  for i, sample in ipairs(sample_positions) do
    print(string.format("\nSample %d:", i))
    print("  File: " .. sample.file)
    print("  Start position: " .. string.format("%.2f", sample.start) .. " seconds")
    print("  End position: " .. string.format("%.2f", sample.end_pos) .. " seconds")
    print("  Duration: " .. string.format("%.2f", sample.end_pos - sample.start) .. " seconds")
  end
  print("\n===============================")
  
  -- Set up voice 1
  softcut.enable(1, 1)
  softcut.buffer(1, 1)
  softcut.level(1, 1.0)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.level_cut_cut(1, 1, 1.0)  -- Voice 1 to output (self-routing)
  softcut.pan(1, -0.5)  -- Pan slightly left
  softcut.loop(1, 1)
  current_sample1 = choose_random_sample_index()
  local sample1_pos = sample_positions[current_sample1]
  print("Voice 1 initial sample: " .. sample1_pos.file)
  softcut.loop_start(1, sample1_pos.start)
  softcut.loop_end(1, sample1_pos.end_pos)
  softcut.position(1, sample1_pos.start)
  softcut.rate(1, 1.0)
  softcut.play(1, 0)
  
  -- Set up voice 2
  softcut.enable(2, 1)
  softcut.buffer(2, 1)
  softcut.level(2, 1.0)
  softcut.level_input_cut(1, 2, 1.0)
  softcut.level_input_cut(2, 2, 1.0)
  softcut.level_cut_cut(2, 2, 1.0)  -- Voice 2 to output (self-routing)
  softcut.pan(2, 0.5)  -- Pan slightly right
  softcut.loop(2, 1)
  current_sample2 = choose_random_sample_index()
  local sample2_pos = sample_positions[current_sample2]
  print("Voice 2 initial sample: " .. sample2_pos.file)
  softcut.loop_start(2, sample2_pos.start)
  softcut.loop_end(2, sample2_pos.end_pos)
  softcut.position(2, sample2_pos.start)
  softcut.rate(2, 1.0)
  softcut.play(2, 0)
  
  -- Set up audio routing
  audio.level_adc_cut(1.0)
  audio.level_eng_cut(1.0)
  audio.level_tape_cut(1.0)
  
  position1 = 0
  position2 = 0
  volume = 1.0
  is_playing = false
  current_samples = samples
  redraw()
end

function key(n,z)
  print("Key pressed: " .. n .. " state: " .. z)
  if n == 2 and z == 1 then
    print("K2 pressed - toggling both voices")
    is_playing = not is_playing
    
    if is_playing then
      -- Choose new random samples for both voices
      current_sample1 = choose_random_sample_index()
      current_sample2 = choose_random_sample_index()
      
      local sample1_pos = sample_positions[current_sample1]
      local sample2_pos = sample_positions[current_sample2]
      
      print("Voice 1 playing sample: " .. sample1_pos.file)
      print("Voice 2 playing sample: " .. sample2_pos.file)
      
      -- Set up voice 1
      softcut.loop_start(1, sample1_pos.start)
      softcut.loop_end(1, sample1_pos.end_pos)
      softcut.position(1, sample1_pos.start)
      
      -- Set up voice 2
      softcut.loop_start(2, sample2_pos.start)
      softcut.loop_end(2, sample2_pos.end_pos)
      softcut.position(2, sample2_pos.start)
    end
    
    -- Toggle both voices
    softcut.play(1, is_playing and 1 or 0)
    softcut.play(2, is_playing and 1 or 0)
    print("Play state: " .. (is_playing and "ON" or "OFF"))
  end
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
    position1 = position1 + (d * 0.1)
    if position1 < 0 then position1 = 0 end
    if position1 > 1 then position1 = 1 end
    local sample_pos = sample_positions[current_sample1]
    local new_pos = sample_pos.start + (position1 * (sample_pos.end_pos - sample_pos.start))
    softcut.position(1, new_pos)
  elseif n == 3 then
    position2 = position2 + (d * 0.1)
    if position2 < 0 then position2 = 0 end
    if position2 > 1 then position2 = 1 end
    local sample_pos = sample_positions[current_sample2]
    local new_pos = sample_pos.start + (position2 * (sample_pos.end_pos - sample_pos.start))
    softcut.position(2, new_pos)
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.move(10, 20)
  screen.text("VOICE 1:")
  screen.move(10, 30)
  screen.text("POS: " .. string.format("%.2f", position1))
  screen.move(10, 40)
  screen.text("VOICE 2:")
  screen.move(10, 50)
  screen.text("POS: " .. string.format("%.2f", position2))
  screen.move(10, 60)
  screen.text("VOL: " .. string.format("%.2f", volume))
  screen.move(10, 70)
  screen.text("PLAY: " .. (is_playing and "ON" or "OFF"))
  screen.move(10, 80)
  screen.text("K2: toggle both voices")
  screen.update()
end

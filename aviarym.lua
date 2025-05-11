-- aviarym
-- minimal sample player
--
-- KEY 2 toggle playback
-- ENC 2 change sample position
-- ENC 3 change volume

local Setup = dofile('/home/we/dust/code/aviarym/setup.lua')

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

-- Function to choose random sample
local function choose_random_sample(samples)
  if not samples or #samples == 0 then
    return nil
  end
  return samples[math.random(1, #samples)]
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
  
  -- Choose initial sample
  local sample_file = choose_random_sample(samples)
  if sample_file then
    print("Loading sample: " .. sample_file)
    -- Read file into buffer 1
    softcut.buffer_read_mono(sample_file, 0, 1, -1, 1, 1)
    
    -- Enable voice 1
    softcut.enable(1, 1)
    -- Set voice 1 to buffer 1
    softcut.buffer(1, 1)
    -- Set voice 1 level
    softcut.level(1, 1.0)
    -- Enable loop
    softcut.loop(1, 1)
    local ch, samples, samplerate = audio.file_info(sample_file)
    local duration = samples / samplerate
    softcut.loop_start(1, 0)
    softcut.loop_end(1, duration)
    softcut.position(1, 0)
    -- Set playback rate
    softcut.rate(1, 1.0)
    -- Start with playback stopped
    softcut.play(1, 0)
  else
    print("No MP3 files found in samples directory")
  end
  
  position = 0
  volume = 1.0
  is_playing = false
  current_samples = samples -- Store samples list for later use
  redraw()
end

function key(n,z)
  if n == 2 and z == 1 then
    if not is_playing then
      -- Choose new random sample when starting playback
      local sample_file = choose_random_sample(current_samples)
      if sample_file then
        print("Loading new sample: " .. sample_file)
        softcut.buffer_clear()
        softcut.buffer_read_mono(sample_file, 0, 1, -1, 1, 1)
        local ch, samples, samplerate = audio.file_info(sample_file)
        local duration = samples / samplerate
        softcut.loop_start(1, 0)
        softcut.loop_end(1, duration)
        softcut.position(1, 0)
      end
    end
    is_playing = not is_playing
    softcut.play(1, is_playing and 1 or 0)
  end
  redraw()
end

function enc(n,d)
  if n == 2 then
    position = position + (d * 0.1)
    if position < 0 then position = 0 end
    if position > 1 then position = 1 end
    softcut.position(1, position)
  elseif n == 3 then
    volume = volume + (d * 0.1)
    if volume < 0 then volume = 0 end
    if volume > 1 then volume = 1 end
    softcut.level(1, volume)
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.move(10, 20)
  screen.text("POS: " .. string.format("%.2f", position))
  screen.move(10, 30)
  screen.text("VOL: " .. string.format("%.2f", volume))
  screen.move(10, 40)
  screen.text("PLAY: " .. (is_playing and "ON" or "OFF"))
  screen.move(10, 50)
  screen.text("Press K2 to toggle")
  screen.update()
end

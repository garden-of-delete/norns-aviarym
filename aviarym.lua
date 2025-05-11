-- aviarym
-- minimal sample player
--
-- KEY 2 toggle playback
-- ENC 2 change sample position
-- ENC 3 change volume

-- Function to find first MP3 file in directory
function find_first_mp3()
  local dir = "/home/we/dust/audio/aviarym/samples"
  local files = io.popen("ls " .. dir .. "/*.mp3 2>/dev/null")
  if files then
    local first_file = files:read("*l")
    files:close()
    return first_file
  end
  return nil
end

function init()
  -- Initialize Softcut parameters
  softcut.buffer_clear()
  
  -- Find and load first MP3
  local sample_file = find_first_mp3()
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
    -- Set loop points
    softcut.loop_start(1, 0)
    softcut.loop_end(1, 1)
    -- Set initial position
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
  redraw()
end

function key(n,z)
  if n == 2 and z == 1 then
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
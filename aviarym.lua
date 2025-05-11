-- aviarym
-- A norns script
-- v1.0.0

local UI = require "ui"
local MusicUtil = require "musicutil"

-- Initialize variables
local params = {}
local screen = {}
local engine = {}
local sample_path = "/home/we/dust/audio/aviarym/samples/"

-- Helper function to check if directory exists
local function directory_exists(path)
  local ok, err, code = os.rename(path, path)
  if not ok and code == 13 then
    return true
  end
  return ok
end

-- Initialize the script
function init()
  -- Check and create samples directory if it doesn't exist
  if not directory_exists(sample_path) then
    print("Creating samples directory at: " .. sample_path)
    os.execute("mkdir -p " .. sample_path)
  end
  
  -- Initialize parameters
  params:add_separator("AVIARYM")
  params:add{type = "file", id = "sample", name = "Sample", path = sample_path}
  params:add{type = "number", id = "rate", name = "Playback Rate", min = 0.25, max = 4, default = 1, formatter = function(param) return string.format("%.2fx", param:get()) end}
  params:add{type = "number", id = "amp", name = "Amplitude", min = 0, max = 1, default = 0.5, formatter = function(param) return string.format("%.2f", param:get()) end}
  params:add{type = "number", id = "pan", name = "Pan", min = -1, max = 1, default = 0, formatter = function(param) return string.format("%.2f", param:get()) end}
  
  -- Initialize screen
  screen.refresh = function()
    screen.clear()
    screen.move(10, 20)
    screen.text("AVIARYM SAMPLER")
    screen.move(10, 30)
    screen.text("Sample: " .. params:get("sample"))
    screen.move(10, 40)
    screen.text("Rate: " .. string.format("%.2fx", params:get("rate")))
    screen.move(10, 50)
    screen.text("Amp: " .. string.format("%.2f", params:get("amp")))
    screen.move(10, 60)
    screen.text("Pan: " .. string.format("%.2f", params:get("pan")))
    screen.update()
  end
  
  -- Initialize engine
  engine.name = "Aviarym"
  engine.reload()
  
  -- Start the script
  redraw()
end

-- Clean up when script is stopped
function cleanup()
  -- Add any cleanup code here
end

-- Handle key presses
function key(n, z)
  if n == 2 and z == 1 then
    -- Play/stop sample
    if z == 1 then
      engine.load(params:get("sample"))
      engine.play(params:get("rate"))
    end
  elseif n == 3 and z == 1 then
    -- Add your key 3 handler here
  end
  redraw()
end

-- Handle encoder turns
function enc(n, d)
  if n == 1 then
    params:delta("rate", d)
  elseif n == 2 then
    params:delta("amp", d)
    engine.amp(params:get("amp"))
  elseif n == 3 then
    params:delta("pan", d)
    engine.pan(params:get("pan"))
  end
  redraw()
end

-- Redraw the screen
function redraw()
  screen.refresh()
end 
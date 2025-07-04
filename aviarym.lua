-- aviarym (refactored)
-- minimal sample player using cartographer for buffer management
--
-- KEY 2 toggle voice playback
-- KEY 3 toggle all voices
-- ENC 1 change volume for all voices
-- ENC 2 select voice
-- ENC 3 change sample position for selected voice

local Setup = dofile('/home/we/dust/code/aviarym/setup.lua')
local VoiceManager = dofile('/home/we/dust/code/aviarym/voice_manager.lua')
local SampleManager = dofile('/home/we/dust/code/aviarym/sample_manager.lua')
local UIManager = dofile('/home/we/dust/code/aviarym/ui_manager.lua')
local Config = dofile('/home/we/dust/code/aviarym/config.lua')

-- Cartographer loading with error handling
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
  
  -- Load cartographer
  if not load_cartographer() then
    print("Cannot continue without cartographer dependency")
    return
  end
  
  -- Initialize random seed
  math.randomseed(os.time())
  
  -- Initialize sample manager
  if not SampleManager.init(cartographer, Config) then
    print("Failed to initialize samples")
    return
  end
  
  -- Get sample data
  local sample_slices = SampleManager.get_sample_slices()
  local sample_files = SampleManager.get_sample_files()
  
  -- Initialize voice manager
  VoiceManager.init(sample_files, sample_slices, cartographer, Config)
  
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
      print("K2 pressed - toggling voice " .. VoiceManager.get_selected_voice())
      VoiceManager.toggle_voice(VoiceManager.get_selected_voice(), SampleManager.get_sample_slices())
      
    elseif n == 3 then
      print("K3 pressed - toggling ALL voices")
      VoiceManager.toggle_all_voices(SampleManager.get_sample_slices())
    end
    
    redraw()
  end
end

function enc(n,d)
  if n == 1 then
    -- Master volume
    local current_volume = VoiceManager.get_volume()
    VoiceManager.set_volume(current_volume + d * Config.VOLUME_SENSITIVITY)
    
  elseif n == 2 then
    -- Voice selection
    local current_selected = VoiceManager.get_selected_voice()
    VoiceManager.set_selected_voice(current_selected + d)
    
  elseif n == 3 then
    -- Position control for selected voice
    local selected_voice = VoiceManager.get_selected_voice()
    local current_position = VoiceManager.get_voice_position()[selected_voice]
    VoiceManager.set_voice_position(selected_voice, current_position + d * Config.POSITION_SENSITIVITY, SampleManager.get_sample_slices())
  end
  
  redraw()
end

function redraw()
  UIManager.redraw(
    VoiceManager.get_voice_playing(),
    VoiceManager.get_voice_current_sample(),
    VoiceManager.get_voice_position(),
    VoiceManager.get_selected_voice(),
    VoiceManager.get_volume(),
    SampleManager.get_sample_files(),
    VoiceManager.get_voice_count(),
    Config
  )
end

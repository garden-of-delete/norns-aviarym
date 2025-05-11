local Setup = {
  directories_ready = false,
  metadata_ready = false
}

-- Function to ensure directory exists
local function ensure_directory(path)
  local success, err = os.execute("mkdir -p " .. path)
  if not success then
    print("Error creating directory " .. path .. ": " .. tostring(err))
    return false
  end
  return true
end

-- Function to setup required directories
local function setup_directories()
  -- Define required directories
  local audio_dir = "/home/we/dust/audio/aviarym/samples"
  local data_dir = "/home/we/dust/data/aviarym"
  
  -- Create directories if they don't exist
  local audio_success = ensure_directory(audio_dir)
  local data_success = ensure_directory(data_dir)
  
  local success = audio_success and data_success
  
  if success then
    print("Directories verified/created successfully")
  else
    print("Warning: Some directories could not be created")
  end
  
  return success
end

-- Function to create sample metadata file
local function setup_metadata()
  local data_dir = "/home/we/dust/data/aviarym"
  local samples_dir = "/home/we/dust/audio/aviarym/samples"
  local metadata_file = data_dir .. "/samples.json"
  
  -- Get list of WAV files
  local handle = io.popen("find " .. samples_dir .. " -name '*.wav'")
  if not handle then
    print("Error: Could not access samples directory")
    return false
  end
  
  local samples = {}
  for file in handle:lines() do
    table.insert(samples, file)
  end
  handle:close()
  
  -- Create metadata file
  local file = io.open(metadata_file, "w")
  if not file then
    print("Error: Could not create metadata file")
    return false
  end
  
  -- Write sample paths as JSON array
  file:write("{\n  \"samples\": [\n")
  for i, sample in ipairs(samples) do
    file:write("    \"" .. sample .. "\"")
    if i < #samples then
      file:write(",")
    end
    file:write("\n")
  end
  file:write("  ]\n}")
  file:close()
  
  print("Metadata file created successfully")
  return true
end

function Setup.init()
  -- Run all setup procedures
  Setup.directories_ready = setup_directories()
  Setup.metadata_ready = setup_metadata()
  
  -- Add more setup procedures here as needed
  -- local other_success = setup_other_thing()
  
  return Setup.directories_ready and Setup.metadata_ready
end

return Setup 

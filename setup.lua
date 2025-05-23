local Setup = {
  directories_ready = false,
  metadata_ready = false,
  cartographer_ready = false
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

-- Function to check if cartographer is already installed
-- TODO: need to test on a clean install
local function check_cartographer()
  local cartographer_path = "/home/we/dust/code/lib/cartographer/cartographer.lua"
  local file = io.open(cartographer_path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- Function to install cartographer library
local function setup_cartographer()
  print("Checking cartographer library...")
  
  -- Check if already installed
  if check_cartographer() then
    print("Cartographer already installed")
    return true
  end
  
  print("Installing cartographer library...")
  
  -- Ensure lib directory exists
  local lib_dir = "/home/we/dust/code/lib"
  if not ensure_directory(lib_dir) then
    print("Error: Could not create lib directory")
    return false
  end
  
  -- Try to clone cartographer from GitHub
  local clone_cmd = "cd " .. lib_dir .. " && git clone https://github.com/andr-ew/cartographer.git"
  local success = os.execute(clone_cmd)
  
  if success then
    print("Cartographer installed successfully via git")
    return check_cartographer()  -- Verify installation
  else
    print("Git clone failed, trying wget fallback...")
    
    -- Fallback: download as zip and extract
    local cartographer_dir = lib_dir .. "/cartographer"
    ensure_directory(cartographer_dir)
    
    -- Download the main cartographer.lua file directly
    local download_cmd = "wget -O " .. cartographer_dir .. "/cartographer.lua " .. 
                        "https://raw.githubusercontent.com/andr-ew/cartographer/main/cartographer.lua"
    
    local wget_success = os.execute(download_cmd)
    if wget_success then
      print("Cartographer installed successfully via wget")
      return check_cartographer()
    else
      print("Error: Could not install cartographer automatically")
      print("Please install manually:")
      print("1. Download https://github.com/andr-ew/cartographer")
      print("2. Place in /home/we/dust/code/lib/cartographer/")
      return false
    end
  end
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
  print("Running aviarym setup...")
  
  -- Run all setup procedures
  Setup.directories_ready = setup_directories()
  Setup.cartographer_ready = setup_cartographer()
  Setup.metadata_ready = setup_metadata()
  
  -- Print summary
  print("\n=== Setup Summary ===")
  print("Directories: " .. (Setup.directories_ready and "✓" or "✗"))
  print("Cartographer: " .. (Setup.cartographer_ready and "✓" or "✗"))
  print("Metadata: " .. (Setup.metadata_ready and "✓" or "✗"))
  print("=====================")
  
  local all_ready = Setup.directories_ready and Setup.cartographer_ready and Setup.metadata_ready
  if all_ready then
    print("Setup completed successfully!")
  else
    print("Setup completed with warnings - check above for details")
  end
  
  return all_ready
end

return Setup 

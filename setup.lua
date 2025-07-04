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

-- Function to parse bird sound filename and extract metadata
local function parse_bird_filename(filename)
  -- Remove file extension and path
  local base_name = filename:match("([^/]+)%.%w+$") or filename
  
  -- Initialize metadata structure
  local metadata = {
    bird_name = "",
    sound_type = "",
    location = "",
    subspecies = "",
    filename = filename,
    parsed = false
  }
  
  -- Step 1: Check if filename ends with location code pattern
  local location_pattern = "([A-Z][A-Z]%-[A-Z0-9]+)$"
  local location = base_name:match(" " .. location_pattern)
  
  local name_without_location = base_name
  if location then
    -- Remove location from the end to get the main part
    name_without_location = base_name:gsub(" " .. location_pattern, "")
  end
  
  -- Step 2: Parse the main part for "Bird Name ## Sound Type" pattern
  local bird_name, number, sound_type = name_without_location:match("^(.+) (%d+) (.+)$")
  
  if bird_name and number and sound_type then
    -- Check if sound type contains subspecies in parentheses
    local main_sound, subspecies = sound_type:match("^(.+) %(([^%)]+)%)$")
    
    if main_sound and subspecies then
      metadata.sound_type = main_sound
      metadata.subspecies = subspecies
    else
      metadata.sound_type = sound_type
    end
    
    metadata.bird_name = bird_name
    metadata.location = location or ""
    metadata.parsed = true
    return metadata
  end
  
  -- Step 3: Fallback parsing for unusual formats
  local parts = {}
  for word in base_name:gmatch("%S+") do
    table.insert(parts, word)
  end
  
  if #parts >= 3 then
    -- Check if last part is location
    local last_part = parts[#parts]
    if last_part:match("^[A-Z][A-Z]%-[A-Z0-9]+$") then
      metadata.location = last_part
      table.remove(parts, #parts)
    end
    
    -- Find number to separate bird name from sound type
    local number_index = nil
    for i, part in ipairs(parts) do
      if part:match("^%d+$") then
        number_index = i
        break
      end
    end
    
    if number_index and number_index > 1 and number_index < #parts then
      -- Bird name is everything before the number
      local bird_parts = {}
      for i = 1, number_index - 1 do
        table.insert(bird_parts, parts[i])
      end
      metadata.bird_name = table.concat(bird_parts, " ")
      
      -- Sound type is everything after the number
      local sound_parts = {}
      for i = number_index + 1, #parts do
        table.insert(sound_parts, parts[i])
      end
      metadata.sound_type = table.concat(sound_parts, " ")
      metadata.parsed = true
    else
      -- Complete fallback
      metadata.bird_name = base_name
      metadata.sound_type = "Unknown"
      metadata.location = ""
      metadata.parsed = false
    end
  else
    -- Too few parts, treat as unparsed
    metadata.bird_name = base_name
    metadata.sound_type = "Unknown"
    metadata.location = ""
    metadata.parsed = false
  end
  
  return metadata
end

-- Function to create comprehensive sample metadata file
local function setup_metadata()
  local data_dir = "/home/we/dust/data/aviarym"
  local samples_dir = "/home/we/dust/audio/aviarym/samples"
  local metadata_file = data_dir .. "/samples_metadata.json"
  
  -- Get list of WAV files
  local handle = io.popen("find " .. samples_dir .. " -name '*.wav' -o -name '*.mp3'")
  if not handle then
    print("Error: Could not access samples directory")
    return false
  end
  
  local sample_files = {}
  for file in handle:lines() do
    table.insert(sample_files, file)
  end
  handle:close()
  
  if #sample_files == 0 then
    print("No audio files found in samples directory")
    return false
  end
  
  -- Parse metadata for each file
  print("Parsing metadata for " .. #sample_files .. " files...")
  local samples_metadata = {}
  local parsed_count = 0
  
  for i, file_path in ipairs(sample_files) do
    local metadata = parse_bird_filename(file_path)
    samples_metadata[i] = metadata
    
    if metadata.parsed then
      parsed_count = parsed_count + 1
    end
    
    -- Print progress for every 10th file or if parsing failed
    if i % 10 == 0 or not metadata.parsed then
      print("  " .. i .. "/" .. #sample_files .. ": " .. 
            (metadata.parsed and "✓" or "✗") .. " " .. metadata.bird_name)
    end
  end
  
  -- Create metadata file
  local file = io.open(metadata_file, "w")
  if not file then
    print("Error: Could not create metadata file")
    return false
  end
  
  -- Write comprehensive metadata as JSON
  file:write("{\n")
  file:write("  \"generated_at\": \"" .. os.date("%Y-%m-%d %H:%M:%S") .. "\",\n")
  file:write("  \"total_files\": " .. #sample_files .. ",\n")
  file:write("  \"parsed_files\": " .. parsed_count .. ",\n")
  file:write("  \"samples\": [\n")
  
  for i, metadata in ipairs(samples_metadata) do
    file:write("    {\n")
    file:write("      \"filename\": \"" .. metadata.filename .. "\",\n")
    file:write("      \"bird_name\": \"" .. metadata.bird_name .. "\",\n")
    file:write("      \"sound_type\": \"" .. metadata.sound_type .. "\",\n")
    file:write("      \"location\": \"" .. metadata.location .. "\",\n")
    file:write("      \"subspecies\": \"" .. metadata.subspecies .. "\",\n")
    file:write("      \"parsed\": " .. (metadata.parsed and "true" or "false") .. "\n")
    file:write("    }")
    if i < #samples_metadata then
      file:write(",")
    end
    file:write("\n")
  end
  
  file:write("  ]\n")
  file:write("}")
  file:close()
  
  print("Metadata file created successfully: " .. metadata_file)
  print("Successfully parsed " .. parsed_count .. "/" .. #sample_files .. " files")
  
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

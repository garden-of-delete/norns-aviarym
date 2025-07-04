-- Sample Manager Module
-- Handles sample loading and cartographer slice management

local SampleManager = {}

-- Sample state
local sample_slices = {}
local sample_files = {}

-- Function to read comprehensive metadata file
local function read_metadata()
  local file = io.open("/home/we/dust/data/aviarym/samples_metadata.json", "r")
  if not file then
    print("Error: Could not open metadata file")
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Simple JSON parsing for our specific format
  local samples = {}
  local metadata = {}
  
  -- Parse the JSON structure
  -- Look for the samples array
  local samples_section = content:match('"samples":%s*%[(.-)%]')
  if not samples_section then
    print("Error: Could not find samples array in metadata file")
    return nil
  end
  
  -- Parse each sample object
  local sample_objects = {}
  for sample_obj in samples_section:gmatch('{(.-)}') do
    local sample_data = {}
    
    -- Extract filename
    local filename = sample_obj:match('"filename":%s*"([^"]+)"')
    if filename then
      sample_data.filename = filename
    end
    
    -- Extract bird name
    local bird_name = sample_obj:match('"bird_name":%s*"([^"]*)"')
    if bird_name then
      sample_data.bird_name = bird_name
    end
    
    -- Extract sound type
    local sound_type = sample_obj:match('"sound_type":%s*"([^"]*)"')
    if sound_type then
      sample_data.sound_type = sound_type
    end
    
    -- Extract location
    local location = sample_obj:match('"location":%s*"([^"]*)"')
    if location then
      sample_data.location = location
    end
    
    -- Extract subspecies
    local subspecies = sample_obj:match('"subspecies":%s*"([^"]*)"')
    if subspecies then
      sample_data.subspecies = subspecies
    end
    
    -- Extract parsed status
    local parsed = sample_obj:match('"parsed":%s*(%w+)')
    if parsed then
      sample_data.parsed = (parsed == "true")
    end
    
    if sample_data.filename and sample_data.filename:match("%.wav$") then
      table.insert(samples, sample_data.filename)
      table.insert(sample_objects, sample_data)
    end
  end
  
  if #samples == 0 then
    print("No WAV samples found in metadata file")
    return nil
  end
  
  print("Loaded metadata for " .. #samples .. " samples")
  return samples, sample_objects
end

function SampleManager.init(cartographer_instance, config)
  -- Read metadata and get available samples
  local samples, sample_metadata = read_metadata()
  if not samples then
    print("No samples available")
    return false
  end
  
  sample_files = samples
  print("Found " .. #sample_files .. " samples")
  
  -- Store metadata for later use
  SampleManager.metadata = sample_metadata or {}
  
  -- Print some sample information
  if sample_metadata then
    local parsed_count = 0
    local unique_birds = {}
    local unique_locations = {}
    
    for _, meta in ipairs(sample_metadata) do
      if meta.parsed then
        parsed_count = parsed_count + 1
      end
      if meta.bird_name and meta.bird_name ~= "" then
        unique_birds[meta.bird_name] = true
      end
      if meta.location and meta.location ~= "" then
        unique_locations[meta.location] = true
      end
    end
    
    local bird_count = 0
    for _ in pairs(unique_birds) do bird_count = bird_count + 1 end
    local location_count = 0
    for _ in pairs(unique_locations) do location_count = location_count + 1 end
    
    print("  " .. parsed_count .. " parsed successfully")
    print("  " .. bird_count .. " unique bird species")
    print("  " .. location_count .. " unique locations")
  end
  
  -- Clear buffers
  print("\nClearing buffers...")
  softcut.buffer_clear()
  
  -- Create slices for samples using cartographer
  print("Setting up cartographer slices...")
  
  -- Divide buffer 1 into slices for our samples
  -- We'll use both buffers to maximize available space
  local max_slices_per_buffer = config.MAX_SLICES_PER_BUFFER
  local buffer1_slices = cartographer_instance.divide(cartographer_instance.buffer[1], math.min(#sample_files, max_slices_per_buffer))
  local buffer2_slices = cartographer_instance.divide(cartographer_instance.buffer[2], math.min(#sample_files - max_slices_per_buffer, max_slices_per_buffer))
  
  -- Combine slices from both buffers
  sample_slices = {}
  for i = 1, math.min(#sample_files, max_slices_per_buffer) do
    sample_slices[i] = buffer1_slices[i]
  end
  for i = 1, math.min(#sample_files - max_slices_per_buffer, max_slices_per_buffer) do
    sample_slices[i + max_slices_per_buffer] = buffer2_slices[i]
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
  
  return true
end

-- Getters
function SampleManager.get_sample_slices() return sample_slices end
function SampleManager.get_sample_files() return sample_files end
function SampleManager.get_sample_metadata() return SampleManager.metadata or {} end

return SampleManager 
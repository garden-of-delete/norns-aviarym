-- Sample Manager Module
-- Handles sample loading and cartographer slice management

local SampleManager = {}

-- Sample state
local sample_slices = {}
local sample_files = {}

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

function SampleManager.init(cartographer_instance, config)
  -- Read metadata and get available samples
  local samples = read_metadata()
  if not samples then
    print("No samples available")
    return false
  end
  
  sample_files = samples
  print("Found " .. #sample_files .. " samples")
  
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

return SampleManager 
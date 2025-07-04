-- Configuration file for aviarym
-- Centralizes all constants and settings

local Config = {
  -- Voice settings
  VOICE_COUNT = 6,  -- six voice hardware limit due to softcut
  DEFAULT_VOLUME = 1.0,
  
  -- File paths
  METADATA_FILE = "/home/we/dust/data/aviarym/samples_metadata.json",
  SAMPLES_DIR = "/home/we/dust/audio/aviarym/samples",
  
  -- Cartographer settings
  CARTOGRAPHER_PATH = "/home/we/dust/code/lib/cartographer/cartographer",
  
  -- UI settings
  MAX_SAMPLE_NAME_LENGTH = 12,
  TRUNCATE_LENGTH = 9,
  
  -- Audio settings
  DEFAULT_PAN_SPREAD = true,  -- Spread voices across stereo field
  STEREO_PAN_RANGE = 0.8,     -- Stereo field range (-0.8 to +0.8 instead of -1 to +1)
  
  -- Buffer management
  MAX_SLICES_PER_BUFFER = 3,
  
  -- Control sensitivity
  VOLUME_SENSITIVITY = 0.01,
  POSITION_SENSITIVITY = 0.01
}

return Config 
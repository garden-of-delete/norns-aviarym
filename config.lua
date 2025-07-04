-- Configuration file for aviarym
-- Centralizes all constants and settings

local Config = {
  -- Voice settings
  VOICE_COUNT = 6,
  DEFAULT_VOLUME = 1.0,
  
  -- File paths
  METADATA_FILE = "/home/we/dUST/data/aviarym/samples.json",
  SAMPLES_DIR = "/home/we/dUST/audio/aviarym/samples",
  
  -- Cartographer settings
  CARTOGRAPHER_PATH = "/home/we/dUST/code/lib/cartographer/cartographer",
  
  -- UI settings
  MAX_SAMPLE_NAME_LENGTH = 12,
  TRUNCATE_LENGTH = 9,
  
  -- Audio settings
  DEFAULT_PAN_SPREAD = true,  -- Spread voices across stereo field
  
  -- Buffer management
  MAX_SLICES_PER_BUFFER = 3,
  
  -- Control sensitivity
  VOLUME_SENSITIVITY = 0.01,
  POSITION_SENSITIVITY = 0.01
}

return Config 
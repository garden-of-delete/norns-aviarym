-- UI Manager Module
-- Handles screen rendering and UI updates

local UIManager = {}

function UIManager.redraw(voice_playing, voice_current_sample, voice_position, selected_voice, volume, sample_files, voice_count, config)
  screen.clear()
  
  -- Header
  screen.move(64, 10)
  screen.text_center("Aviarym - " .. voice_count .. " Voice Sample Player")
  
  -- Voice status
  for i = 1, voice_count do
    local y = 20 + (i - 1) * 8
    screen.move(10, y)
    
    -- Highlight selected voice
    if i == selected_voice then
      screen.level(15)
      screen.text("> ")
    else
      screen.level(8)
      screen.text("  ")
    end
    
    -- Voice number and status
    screen.text("V" .. i .. ": ")
    
    if voice_playing[i] then
      screen.level(15)
      screen.text("ON  ")
    else
      screen.level(8)
      screen.text("OFF ")
    end
    
    -- Sample name (shortened)
    local sample_index = voice_current_sample[i]
    if sample_index <= #sample_files then
      local filename = sample_files[sample_index]
      local short_name = filename:match("([^/]+)%.wav$") or filename
      -- Truncate if too long
      if #short_name > config.MAX_SAMPLE_NAME_LENGTH then
        short_name = short_name:sub(1, config.TRUNCATE_LENGTH) .. "..."
      end
      screen.text(short_name)
    end
    
    -- Position for selected voice
    if i == selected_voice then
      screen.move(90, y)
      screen.text(string.format("%.2f", voice_position[i]))
    end
  end
  
  -- Controls
  screen.move(10, 78)
  screen.level(8)
  screen.text("E1: volume  E2: select voice  E3: position")
  screen.move(10, 88)
  screen.text("K2: toggle voice  K3: toggle all")
  screen.move(10, 98)
  screen.text("VOL: " .. string.format("%.2f", volume))
  
  screen.update()
end

return UIManager 
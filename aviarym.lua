-- aviarym
-- minimal sample player
--
-- KEY 2 play note
-- ENC 2 change note
-- ENC 3 change velocity

local MusicUtil = require "musicutil"

engine.name = "PolyPerc"

function init()
  note = 60  -- middle C
  velocity = 100
  engine.amp(0.5)
  redraw()  -- initial screen draw
end

function key(n,z)
  if n == 2 and z == 1 then
    local freq = MusicUtil.note_num_to_freq(note)
    engine.hz(freq)
    engine.amp(velocity / 127)
  end
  redraw()  -- redraw after key press
end

function enc(n,d)
  if n == 2 then
    note = note + d
    if note < 0 then note = 0 end
    if note > 127 then note = 127 end
  elseif n == 3 then
    velocity = velocity + d
    if velocity < 0 then velocity = 0 end
    if velocity > 127 then velocity = 127 end
  end
  redraw()  -- redraw after encoder turn
end

function redraw()
  screen.clear()
  screen.move(10, 20)
  screen.text("NOTE: " .. note)
  screen.move(10, 30)
  screen.text("VEL: " .. velocity)
  screen.move(10, 50)
  screen.text("Press K2 to play")
  screen.update()
end
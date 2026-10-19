-- slime-walk.lua — a 4-direction slime hop cycle, exported as an animated GIF.
--
-- Consistency rules (from pixel-art-rules):
--  * one character seen from several sides, shared canvas + foot row + palette
--  * a cycle built from squash/stretch key poses, not re-drawn blobs
--  * stable cluster structure between frames; eyes move as a unit
--
-- 16x16 cells per frame. Directions: down, up, left, right. 4 frames each
-- (contact-squash, rise, peak-stretch, fall) = a looping hop.
-- Env: SLIME_OUT (default slime-walk.gif), SLIME_SCALE (default 10),
--      SLIME_MS (frame ms, default 120).

local out   = os.getenv("SLIME_OUT")   or "slime-walk.gif"
local scale = tonumber(os.getenv("SLIME_SCALE") or "10")
local ms    = tonumber(os.getenv("SLIME_MS") or "120")

local N = 16                     -- cell size
-- palette (hue-shifted green ramp + eyes + shine)
local BG    = nil                              -- transparent
local BODY  = Color{ r=0x4f, g=0xc0, b=0x5a }  -- mid green
local DARK  = Color{ r=0x2e, g=0x7d, b=0x55 }  -- cool shadow (hue shifted blue)
local LIGHT = Color{ r=0x9c, g=0xe8, b=0x7a }  -- warm highlight (hue shifted yellow)
local EYE   = Color{ r=0x14, g=0x1a, b=0x22 }
local SHINE = Color{ r=0xf2, g=0xff, b=0xe0 }

-- Build a slime body as a rounded blob given width/height and squash offset.
-- Returns a function that paints onto an Image at (ox,oy) with a direction.
-- We draw procedurally: an ellipse blob + a flat bottom, shaded with a light
-- from upper-left, plus eyes placed per direction.

local function make_frame(dir, phase)
  -- phase 1..4: 1 contact(squash wide/low), 2 rise, 3 peak(tall/narrow), 4 fall
  local img = Image(N, N)
  img:clear()

  -- squash/stretch params per phase (keep volume roughly constant)
  local w, h, yoff
  if phase == 1 then w, h, yoff = 13, 9, 7
  elseif phase == 2 then w, h, yoff = 12, 11, 4
  elseif phase == 3 then w, h, yoff = 10, 13, 2
  else w, h, yoff = 12, 11, 4 end

  local cx = N/2 - 0.5
  local cyTop = yoff
  local a = w/2        -- x radius
  local b = h/2        -- y radius
  local cy = cyTop + b

  -- draw filled ellipse with 3-tone shading from upper-left
  for y = 0, N-1 do
    for x = 0, N-1 do
      local nx = (x - cx) / a
      local ny = (y - cy) / b
      local d = nx*nx + ny*ny
      if d <= 1.0 then
        -- shading by light dir (-1,-1): lit upper-left, shadow lower-right
        local ld = (-nx + -ny)
        local col
        if ld > 0.75 then col = LIGHT
        elseif ld < -0.55 then col = DARK
        else col = BODY end
        img:drawPixel(x, y, col)
      end
    end
  end
  -- flat-ish bottom contact shadow row (darker) when squashed
  if phase == 1 then
    for x = 2, N-3 do
      local yb = math.floor(cy + b) - 1
      if yb >= 0 and yb < N then
        local p = img:getPixel(yb and x or x, yb)
        if img:getPixel(x, yb) ~= 0 then img:drawPixel(x, yb, DARK) end
      end
    end
  end

  -- a small specular shine (single allowed highlight) upper-left of the blob
  img:drawPixel(math.floor(cx - a*0.4), math.floor(cy - b*0.5), SHINE)

  -- eyes per direction (move as a unit). Place relative to center.
  local function eye(px, py)
    img:drawPixel(px, py, EYE)
    img:drawPixel(px, py+1, EYE)
  end
  local ecy = math.floor(cy - b*0.15)
  if dir == "down" then
    eye(math.floor(cx - 2), ecy); eye(math.floor(cx + 2), ecy)
  elseif dir == "up" then
    -- facing away: no eyes, just a faint back highlight band
    for x = math.floor(cx-3), math.floor(cx+3) do
      if img:getPixel(x, ecy) ~= 0 then img:drawPixel(x, ecy, LIGHT) end
    end
  elseif dir == "left" then
    eye(math.floor(cx - 3), ecy); eye(math.floor(cx), ecy)
  elseif dir == "right" then
    eye(math.floor(cx), ecy); eye(math.floor(cx + 3), ecy)
  end

  return img
end

-- Build sprite: 4 directions × 4 phases laid out as frames; tag each direction.
local dirs = {"down", "up", "left", "right"}
local sprite = Sprite(N, N, ColorMode.RGB)
while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
-- remove default empty frame handling: we'll create frames as we go
local layer = sprite.layers[1]

local frameIndex = 0
for di, dir in ipairs(dirs) do
  for phase = 1, 4 do
    frameIndex = frameIndex + 1
    local fr
    if frameIndex == 1 then fr = sprite.frames[1] else fr = sprite:newEmptyFrame() end
    fr.duration = ms / 1000
    local cel = sprite:newCel(layer, fr)
    cel.image = make_frame(dir, phase)
  end
end

-- tags per direction (4 frames each)
local function addtag(name, from, to)
  local t = sprite:newTag(from, to); t.name = name
end
addtag("down", 1, 4)
addtag("up", 5, 8)
addtag("left", 9, 12)
addtag("right", 13, 16)

sprite:saveAs(out:gsub("%.gif$", ".aseprite"))
-- export animated GIF (scaled). Use the CLI-style command via app.command.
local scaled = Sprite(sprite.width * scale, sprite.height * scale, ColorMode.RGB)
-- simplest robust path: resize a copy with nearest neighbour then save as gif
local copy = Sprite(sprite)
copy:resize(sprite.width * scale, sprite.height * scale)
copy:saveAs(out)
print(string.format("OK wrote %s (%d frames, %dx%d @ %dms)", out, #sprite.frames, copy.width, copy.height, ms))

-- kiro-logo.lua — Kiro ghost logo in pixel art (32x32 cells, scaled up)
-- Headless: aseprite -b --script kiro-logo.lua --script-param out=kiro-pixel.png --script-param scale=16

local p = app.params or {}
local out = p.out or "kiro-pixel.png"
local scale = tonumber(p.scale or "16")

-- Palette
local BG_DARK  = Color{ r = 0x6D, g = 0x28, b = 0xD9 }  -- deep violet (bottom)
local BG_LIGHT = Color{ r = 0x8B, g = 0x5C, b = 0xF6 }  -- lighter violet (top)
local WHITE    = Color{ r = 0xFA, g = 0xFA, b = 0xFF }  -- ghost body
local SHADOW   = Color{ r = 0xDD, g = 0xD6, b = 0xF5 }  -- soft shade on ghost
local EYE      = Color{ r = 0x12, g = 0x10, b = 0x1A }  -- eyes

-- 32x32 template.
--  .  = background (gradient fill)
--  #  = ghost white
--  s  = ghost soft shadow (right/bottom edge)
--  o  = eye
local TPL = {
  "................................",
  "................................",
  "..............####..............",
  "............########............",
  "..........############..........",
  ".........##############.........",
  ".........###############........",
  "........#################.......",
  "........#################s......",
  ".......###################s.....",
  ".......###################s.....",
  ".......####.oo####.oo#####s.....",
  "......#####oooo##oooo######s....",
  "......#####oooo##oooo######s....",
  "......#####oooo##oooo######s....",
  "......#####oooo##oooo######s....",
  "......######oo####oo#######s....",
  "......#####################s....",
  "......#####################s....",
  ".....######################s....",
  ".....######################s....",
  "....#######################s....",
  "....#######################s....",
  "...########################s....",
  "...########################s....",
  "..#####.######.#######.####s....",
  "..####...####...#####...###s....",
  "..###.....##.....###.....##s....",
  "...........................s....",
  "................................",
  "................................",
  "................................",
}

local W, H = 32, 32
local img = Image(W * scale, H * scale)

-- fill a scale×scale block
local function block(cx, cy, col)
  for dy = 0, scale - 1 do
    for dx = 0, scale - 1 do
      img:drawPixel(cx * scale + dx, cy * scale + dy, col)
    end
  end
end

for y = 0, H - 1 do
  local row = TPL[y + 1]
  for x = 0, W - 1 do
    local ch = row:sub(x + 1, x + 1)
    if ch == "." then
      -- vertical gradient background (lerp light->dark top to bottom)
      local t = y / (H - 1)
      local r = math.floor(BG_LIGHT.red   + (BG_DARK.red   - BG_LIGHT.red)   * t + 0.5)
      local g = math.floor(BG_LIGHT.green + (BG_DARK.green - BG_LIGHT.green) * t + 0.5)
      local b = math.floor(BG_LIGHT.blue  + (BG_DARK.blue  - BG_LIGHT.blue)  * t + 0.5)
      block(x, y, Color{ r = r, g = g, b = b })
    elseif ch == "#" then
      block(x, y, WHITE)
    elseif ch == "s" then
      block(x, y, SHADOW)
    elseif ch == "o" then
      block(x, y, EYE)
    end
  end
end

if app.isUIAvailable == false then
  img:saveAs(out)
  print("wrote " .. out .. " (" .. img.width .. "x" .. img.height .. ")")
else
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
  app.transaction("kiro-logo", function()
    sprite:newCel(sprite.layers[1], 1).image = img
  end)
  app.sprite = sprite
  app.refresh()
end

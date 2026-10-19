-- starry-night.lua — a 64x48 starry night scene.
-- Applies the rulebook: limited hue-shifted palette, ordered (Bayer) dither for
-- the sky gradient, scatter stars with no lattice, a moon with a terminator
-- (not pillow-shaded), dark hills pushed back by low contrast.
-- Headless: GRID_OUT=... GRID_SCALE=... handled below via env; or edit defaults.

local out   = os.getenv("NIGHT_OUT")   or "starry-night.png"
local scale = tonumber(os.getenv("NIGHT_SCALE") or "8")

local W, H = 64, 48

-- Palette (hue-shifted, cool): deep indigo -> violet near horizon.
local SKY_TOP = { r=0x0b, g=0x10, b=0x33 }   -- deep night blue
local SKY_BOT = { r=0x2c, g=0x1c, b=0x48 }   -- muted violet at horizon
local STAR    = Color{ r=0xf5, g=0xf2, b=0xd0 }  -- warm white
local STAR_DIM= Color{ r=0xbf, g=0xc4, b=0xe0 }  -- cool dim star
local MOON_L  = Color{ r=0xff, g=0xf3, b=0xc8 }  -- lit moon
local MOON_M  = Color{ r=0xd9, g=0xc9, b=0xa0 }  -- moon mid
local MOON_S  = Color{ r=0x9a, g=0x93, b=0x9e }  -- moon shadow (cool)
local HILL1   = Color{ r=0x1b, g=0x16, b=0x2e }  -- near hill (darkest)
local HILL2   = Color{ r=0x26, g=0x1e, b=0x3d }  -- far hill (slightly lighter)

local img = Image(W * scale, H * scale)

local function putcell(x, y, col)
  for dy = 0, scale-1 do for dx = 0, scale-1 do
    img:drawPixel(x*scale+dx, y*scale+dy, col)
  end end
end

-- 4x4 Bayer matrix for ordered dithering of the sky gradient.
local BAYER = {
  { 0,  8,  2, 10},
  {12,  4, 14,  6},
  { 3, 11,  1,  9},
  {15,  7, 13,  5},
}

local function lerp(a, b, t) return a + (b - a) * t end

-- horizon line (hills start here)
local HORIZON = 36

-- 1) Sky with vertical gradient + Bayer dither between two mixing colours.
for y = 0, H-1 do
  local t = math.min(1, y / (HORIZON-1))
  -- base interpolated colour
  local r = lerp(SKY_TOP.r, SKY_BOT.r, t)
  local g = lerp(SKY_TOP.g, SKY_BOT.g, t)
  local b = lerp(SKY_TOP.b, SKY_BOT.b, t)
  for x = 0, W-1 do
    -- dither: nudge toward the next band using the Bayer threshold so the
    -- gradient reads smooth with only a few real colours (intentional dither).
    local thr = BAYER[(y % 4) + 1][(x % 4) + 1] / 16
    local bump = (thr - 0.5) * 10       -- +-5 value jitter, ordered not random
    local col = Color{
      r = math.max(0, math.min(255, math.floor(r + bump))),
      g = math.max(0, math.min(255, math.floor(g + bump))),
      b = math.max(0, math.min(255, math.floor(b + bump + 4))),
    }
    putcell(x, y, col)
  end
end

-- 2) Moon upper-left-ish, lit from upper-left: lit cluster + mid + abrupt shadow
local mcx, mcy, mr = 46, 11, 6
for y = mcy-mr, mcy+mr do
  for x = mcx-mr, mcx+mr do
    local dx, dy = x-mcx, y-mcy
    if dx*dx + dy*dy <= mr*mr then
      -- terminator from upper-left light: use the dot with light dir (-1,-1)
      local d = (dx * -1 + dy * -1) / mr   -- >0 lit side
      local col
      if d > 0.45 then col = MOON_L
      elseif d > -0.2 then col = MOON_M
      else col = MOON_S end
      putcell(x, y, col)
    end
  end
end

-- 3) Stars: scatter with no two in the same row/col nearby, none touching,
--    budget ~ one per ~40 cells of sky. Deterministic pseudo-random.
local seed = 1234567
local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n end
local placed = {}
local function far_enough(x, y)
  for _, s in ipairs(placed) do
    if math.abs(s[1]-x) < 3 and math.abs(s[2]-y) < 3 then return false end
    if s[1]==x or s[2]==y then if math.abs(s[1]-x)+math.abs(s[2]-y) < 5 then return false end end
  end
  return true
end
local tries, want = 0, 26
while #placed < want and tries < 2000 do
  tries = tries + 1
  local x = rnd(W)
  local y = rnd(HORIZON - 4)       -- keep stars above the hills
  -- avoid the moon disc
  local dx, dy = x-mcx, y-mcy
  if dx*dx + dy*dy > (mr+3)*(mr+3) and far_enough(x, y) then
    placed[#placed+1] = {x, y}
    local bright = (rnd(10) > 3)
    putcell(x, y, bright and STAR or STAR_DIM)
    -- a few brighter stars get a tiny + (allowed single-object highlight)
    if bright and rnd(10) > 6 then
      if x>0 then putcell(x-1,y,STAR_DIM) end
      if x<W-1 then putcell(x+1,y,STAR_DIM) end
      if y>0 then putcell(x,y-1,STAR_DIM) end
      if y<HORIZON-1 then putcell(x,y+1,STAR_DIM) end
    end
  end
end

-- 4) Hills: two overlapping low-contrast masses, far one lighter (depth by
--    contrast, not blur). Each hill fills from its ridgeline to the bottom, so
--    no bright sky strip shows between them.
local function hill(baseY, amp, period, col, phase)
  for x = 0, W-1 do
    local ridge = math.floor(baseY + amp * math.sin((x + phase) / period))
    if ridge < 0 then ridge = 0 end
    for y = ridge, H-1 do putcell(x, y, col) end
  end
end
-- far hill a touch higher and already dark-ish so the horizon never flares
hill(HORIZON+1, 2.5, 9, HILL2, 3)   -- far hill (lighter), drawn first
hill(HORIZON+4, 3.5, 13, HILL1, 0)  -- near hill (darkest), on top

img:saveAs(out)
print(string.format("OK wrote %s (%dx%d)", out, img.width, img.height))

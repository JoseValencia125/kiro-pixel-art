-- starry-night-vangogh.lua — pixel-art homage to Van Gogh's "The Starry Night"
-- (1889): swirling sky, crescent moon (upper right), 11 haloed stars, the dark
-- flame-cypress on the left, blue rolling hills and a village with a steeple.
-- 80x64 cells. Env: VG_OUT (default), VG_SCALE (default 7).

local out   = os.getenv("VG_OUT")   or "starry-night-vangogh.png"
local scale = tonumber(os.getenv("VG_SCALE") or "7")

local W, H = 80, 64

-- Palette (Van Gogh night): deep blues, cyan swirls, warm star yellows,
-- cypress greens, village ochre.
local C = {
  sky0  = Color{ r=0x0e, g=0x1f, b=0x4c },  -- deepest night blue
  sky1  = Color{ r=0x1c, g=0x35, b=0x74 },  -- mid blue
  sky2  = Color{ r=0x2f, g=0x55, b=0x9e },  -- lighter blue
  swirl = Color{ r=0x5b, g=0x8f, b=0xcf },  -- cyan-blue swirl
  swirlL= Color{ r=0x9f, g=0xc8, b=0xe6 },  -- pale swirl crest
  star  = Color{ r=0xf2, g=0xd8, b=0x66 },  -- star yellow
  starL = Color{ r=0xff, g=0xf4, b=0xc0 },  -- star core
  halo  = Color{ r=0x7d, g=0x8f, b=0x6e },  -- greenish star halo
  moon  = Color{ r=0xf5, g=0xc8, b=0x4a },  -- moon yellow
  moonL = Color{ r=0xff, g=0xef, b=0xb0 },  -- moon bright
  cyp0  = Color{ r=0x12, g=0x20, b=0x1c },  -- cypress darkest
  cyp1  = Color{ r=0x22, g=0x3a, b=0x2a },  -- cypress mid green
  cyp2  = Color{ r=0x3a, g=0x55, b=0x38 },  -- cypress light green
  hill0 = Color{ r=0x14, g=0x2b, b=0x4e },  -- hills dark
  hill1 = Color{ r=0x22, g=0x40, b=0x6b },  -- hills light
  vwall = Color{ r=0x2a, g=0x33, b=0x50 },  -- village walls
  vwin  = Color{ r=0xf0, g=0xc8, b=0x5a },  -- lit windows
  spire = Color{ r=0x20, g=0x30, b=0x40 },  -- steeple
}

local img = Image(W, H)

local function put(x, y, col)
  if x>=0 and y>=0 and x<W and y<H then img:drawPixel(x, y, col) end
end
local function putS(x, y, col)  -- for the scaled final; here 1:1, scaling later
  put(x, y, col)
end

-- 1) Sky base: vertical bands of blue (darker top-left, lighter mid).
for y = 0, H-1 do
  for x = 0, W-1 do
    local t = y / (H-1)
    local col = C.sky0
    if t > 0.18 and t < 0.55 then col = C.sky1 end
    if t >= 0.1 and t < 0.2 then col = C.sky1 end
    put(x, y, col)
  end
end

-- 2) Swirls: two big spiral bands in the sky, drawn as parametric curves.
local function swirl(cx, cy, r0, r1, turns, col, thick)
  local steps = 260
  for i = 0, steps do
    local a = (i/steps) * turns * 2*math.pi
    local r = r0 + (r1 - r0) * (i/steps)
    local x = cx + math.cos(a) * r
    local y = cy + math.sin(a) * r * 0.62   -- flatten vertically
    for tx = -thick, thick do
      for ty = -thick, thick do
        if tx*tx+ty*ty <= thick*thick then put(math.floor(x+tx), math.floor(y+ty), col) end
      end
    end
  end
end
-- central big swirl
swirl(44, 22, 2, 12, 1.6, C.swirl, 1)
swirl(44, 22, 1, 9,  1.6, C.swirlL, 0)
-- second smaller swirl to the left
swirl(20, 16, 1.5, 7, 1.4, C.swirl, 1)
-- a few wavy cloud bands (horizontal sine ribbons)
for ribbon = 0, 5 do
  local by = 5 + ribbon*6
  local amp = 2.4 + 0.5*ribbon
  local per = 6.0 + ribbon
  for x = 0, W-1 do
    -- stagger the phase so ribbons do not share start/end rows (anti-banding)
    local y = math.floor(by + amp*math.sin((x/per) + ribbon*1.3))
    put(x, y, C.swirl)
    put(x+1, y, C.swirlL)
    if ribbon % 2 == 0 then put(x, y+1, C.sky2) end
  end
end

-- 3) Stars (haloed): list of centers; big yellow dot + green halo ring.
local stars = {
  {10,10},{24,6},{33,12},{55,8},{64,14},{70,24},{60,28},{16,22},{49,6},{72,34},{7,30}
}
for _, s in ipairs(stars) do
  local x, y = s[1], s[2]
  for dx=-2,2 do for dy=-2,2 do
    if dx*dx+dy*dy<=4 then put(x+dx,y+dy,C.halo) end
  end end
  for dx=-1,1 do for dy=-1,1 do
    if dx*dx+dy*dy<=2 then put(x+dx,y+dy,C.star) end
  end end
  put(x,y,C.starL)
end

-- 4) Crescent moon upper-right with glow.
local mcx, mcy = 70, 12
for dx=-4,4 do for dy=-4,4 do
  if dx*dx+dy*dy<=16 then put(mcx+dx,mcy+dy,C.halo) end
end end
for dx=-3,3 do for dy=-3,3 do
  if dx*dx+dy*dy<=9 then put(mcx+dx,mcy+dy,C.moon) end
end end
-- carve crescent: subtract an offset disc with sky, leaving a C shape
for dx=-3,3 do for dy=-3,3 do
  if (dx-2)*(dx-2)+dy*dy<=7 then put(mcx+dx,mcy+dy,C.sky0) end
end end
put(mcx-1,mcy-1,C.moonL)

-- 5) Hills (lower ~1/4): two rolling blue bands.
local HILLY = 48
for x = 0, W-1 do
  local r1 = math.floor(HILLY + 3*math.sin(x/11.0) + 2*math.sin(x/4.0))
  for y = r1, H-1 do put(x, y, C.hill1) end
  local r0 = math.floor(HILLY+4 + 3.5*math.sin(x/9.0 + 1.5))
  for y = r0, H-1 do put(x, y, C.hill0) end
end

-- 6) Village: a row of little houses with lit windows + a central steeple.
for hx = 18, 58, 6 do
  local base = HILLY + 3
  for x = hx, hx+4 do for y = base-3, base do put(x, y, C.vwall) end end
  put(hx+1, base-1, C.vwin); put(hx+3, base-2, C.vwin)
end
-- church steeple near center
local sx = 40
for y = HILLY-6, HILLY+2 do put(sx, y, C.spire); put(sx+1, y, C.spire) end
for y = HILLY-9, HILLY-6 do put(sx, y, C.spire) end   -- pointed top

-- 7) Cypress: tall dark flame-shape on the left, foreground, from bottom up.
local ccx = 12
for y = 2, H-1 do
  -- flame cypress: near-full-height, widening downward, wavy edges, pointed tip
  local fromTop = y / (H-1)              -- 0 at top .. 1 at bottom
  local halfw = 0.5 + 6.5*fromTop        -- narrow tip, broad base
  local wobble = 2.2*math.sin(y/4.0) + 1.1*math.sin(y/1.7)
  local edgewob = 1.0*math.sin(y/2.3)
  local hw = halfw + edgewob
  for dx = -math.floor(hw), math.floor(hw) do
    local x = math.floor(ccx + wobble + dx)
    local col = C.cyp0
    if dx < -hw*0.45 then col = C.cyp1 end        -- left lick lighter
    if dx >  hw*0.45 then col = C.cyp2 end        -- right lick lightest
    put(x, y, col)
  end
end
-- a couple of flame tips licking upward past the tip
put(math.floor(ccx), 1, C.cyp1)
put(math.floor(ccx)+1, 2, C.cyp2)

-- scale up with nearest neighbour by writing a bigger image
local big = Image(W*scale, H*scale)
for y=0,H-1 do for x=0,W-1 do
  local v = img:getPixel(x,y)
  for dy=0,scale-1 do for dx=0,scale-1 do big:drawPixel(x*scale+dx, y*scale+dy, v) end end
end end
big:saveAs(out)
print(string.format("OK wrote %s (%dx%d)", out, big.width, big.height))

-- sword-run.lua — an 8-frame side-view RUN cycle of a swordsman, facing right.
-- Applies the animation rulebook:
--   * step = contact -> down -> pass -> up; two steps = 8 frames
--   * contact is the widest pose; an airborne frame exists (run, not walk)
--   * forward torso lean; arms/legs in opposition; vertical bob
--   * sword held out, trailing a beat (secondary motion)
-- Exports sword-run.gif. Env: SR_OUT, SR_SCALE (default 9), SR_MS (default 70).

local out   = os.getenv("SR_OUT")   or "sword-run.gif"
local scale = tonumber(os.getenv("SR_SCALE") or "9")
local ms    = tonumber(os.getenv("SR_MS") or "70")

local N = 24                        -- cell size (square)
local C = {
  skin = Color{ r=0xe8, g=0xb4, b=0x8f },
  skinD= Color{ r=0xb5, g=0x7e, b=0x5f },
  tunic= Color{ r=0x4a, g=0x6c, b=0xc0 },   -- blue tunic
  tunicD=Color{ r=0x2e, g=0x46, b=0x86 },
  pants= Color{ r=0x3a, g=0x35, b=0x48 },
  boot = Color{ r=0x5a, g=0x3a, b=0x24 },
  hair = Color{ r=0x5a, g=0x38, b=0x24 },
  blade= Color{ r=0xd8, g=0xdd, b=0xe6 },
  bladeL=Color{ r=0xff, g=0xff, b=0xff },
  hilt = Color{ r=0xc8, g=0x9a, b=0x3a },
  out  = Color{ r=0x1a, g=0x16, b=0x22 },   -- outline / darkest
}

-- Helper to paint one run frame given per-frame params.
-- Params describe body bob, lean, leg phase (front/back foot positions) and the
-- sword hand position. Values are in cell coordinates.
local function draw_frame(p)
  local img = Image(N, N)
  img:clear()
  local function px(x, y, c) if x>=0 and y>=0 and x<N and y<N then img:drawPixel(x, y, c) end end
  local function rect(x0,y0,x1,y1,c) for y=y0,y1 do for x=x0,x1 do px(x,y,c) end end end
  local function limb(x0,y0,x1,y1,c)      -- thick-ish line (Bresenham, 1px + dup)
    local dx=math.abs(x1-x0); local dy=math.abs(y1-y0)
    local sx = x0<x1 and 1 or -1; local sy = y0<y1 and 1 or -1
    local err=dx-dy; local x,y=x0,y0
    while true do
      px(x,y,c); px(x+1,y,c)
      if x==x1 and y==y1 then break end
      local e2=2*err
      if e2>-dy then err=err-dy; x=x+sx end
      if e2<dx then err=err+dx; y=y+sy end
    end
  end

  local cx = 10                      -- body center x
  local hipY = 13 + p.bob            -- hip height varies with bob
  local lean = p.lean                -- forward lean offset at the shoulders

  -- LEGS (behind torso). p.legF / p.legB = {dx,dy} of each foot from hip.
  local hipX = cx
  limb(hipX, hipY, hipX + p.legB[1], hipY + p.legB[2], C.pants)   -- back leg
  px(hipX + p.legB[1], hipY + p.legB[2]+1, C.boot); px(hipX + p.legB[1]+1, hipY + p.legB[2]+1, C.boot)
  limb(hipX, hipY, hipX + p.legF[1], hipY + p.legF[2], C.pants)   -- front leg
  px(hipX + p.legF[1], hipY + p.legF[2]+1, C.boot); px(hipX + p.legF[1]+1, hipY + p.legF[2]+1, C.boot)

  -- TORSO (leaning forward): a blue block from hip up to shoulders
  local shX = cx + lean
  local shY = hipY - 5
  rect(math.min(hipX,shX), shY, math.max(hipX,shX)+2, hipY, C.tunic)
  -- torso shading on the lower-right
  rect(math.max(hipX,shX)+1, shY+2, math.max(hipX,shX)+2, hipY, C.tunicD)

  -- HEAD
  local hx, hy = shX+1, shY-4
  rect(hx, hy, hx+3, hy+3, C.skin)
  rect(hx, hy-1, hx+3, hy, C.hair)         -- hair cap
  px(hx+3, hy+1, C.skinD)                   -- cheek shade
  px(hx+3, hy+2, C.out)                     -- nose/eye hint facing right

  -- BACK ARM (opposition): swings opposite the front leg
  limb(shX+1, shY+1, shX+1 + p.armB[1], shY+1 + p.armB[2], C.skin)

  -- FRONT ARM holds the SWORD, hand position p.hand (from shoulder)
  local handX, handY = shX+1 + p.hand[1], shY+1 + p.hand[2]
  limb(shX+1, shY+1, handX, handY, C.skin)
  -- hilt at the hand
  px(handX, handY, C.hilt); px(handX, handY+1, C.hilt)
  -- BLADE extends from the hand in the sword angle p.sword = {dx,dy}
  local bx, by = handX, handY
  local sdx, sdy = p.sword[1], p.sword[2]
  for i=1,8 do
    local x = math.floor(handX + sdx*i/8*7)
    local y = math.floor(handY + sdy*i/8*7)
    px(x, y, C.blade)
    if i>=6 then px(x,y,C.bladeL) end       -- bright tip
  end

  -- motion trail under the feet on the airborne frame (small speed lines)
  if p.air then
    px(2, hipY+5, C.tunicD); px(4, hipY+6, C.tunicD); px(1, hipY+6, C.tunicD)
  end

  return img
end

-- 8 run poses. Two steps; frame 1 & 5 are contacts (widest), 3 & 7 passes,
-- 2/6 down, 4/8 up (one of the ups is the airborne peak).
-- legF/legB are {dx,dy} foot offsets from hip; +x forward(right), +y down.
local F = {
  -- STEP A (right leg leads) ----------------------------------------------
  -- 1 contact A: right foot forward, left foot back (widest), sword swung back
  { bob=0,  lean=3, legF={6,6},  legB={-6,5}, armB={-5,2}, hand={4,2}, sword={0.6,0.8}, air=false },
  -- 2 down A: body lowest, legs gather, sword starting to rise
  { bob=2,  lean=3, legF={3,7},  legB={-2,6}, armB={-3,3}, hand={5,1}, sword={1.0,0.2}, air=false },
  -- 3 pass A: legs under body, body rising, sword forward
  { bob=-1, lean=4, legF={1,6},  legB={2,6},  armB={-1,3}, hand={6,0}, sword={1.0,-0.4}, air=false },
  -- 4 airborne A: both feet off ground, body highest, sword thrust up-forward
  { bob=-3, lean=5, legF={5,2},  legB={-5,3}, armB={-5,0}, hand={7,-1},sword={1.0,-0.6}, air=true },
  -- STEP B (left leg leads) -----------------------------------------------
  -- 5 contact B: left foot forward, right foot back; sword swung back (mirror of 1)
  { bob=0,  lean=3, legF={4,6},  legB={-7,6}, armB={-6,1}, hand={4,2}, sword={0.6,0.9}, air=false },
  -- 6 down B
  { bob=2,  lean=3, legF={2,7},  legB={-4,6}, armB={-4,2}, hand={5,1}, sword={1.0,0.1}, air=false },
  -- 7 pass B
  { bob=-1, lean=4, legF={2,6},  legB={0,6},  armB={-2,3}, hand={6,0}, sword={1.0,-0.4}, air=false },
  -- 8 airborne B
  { bob=-3, lean=5, legF={6,3},  legB={-4,2}, armB={-5,0}, hand={7,-1},sword={1.0,-0.6}, air=true },
}

local sprite = Sprite(N, N, ColorMode.RGB)
while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
local layer = sprite.layers[1]
for i, p in ipairs(F) do
  local fr = (i==1) and sprite.frames[1] or sprite:newEmptyFrame()
  fr.duration = ms/1000
  sprite:newCel(layer, fr).image = draw_frame(p)
end
local tag = sprite:newTag(1, #F); tag.name = "run"

sprite:saveAs(out:gsub("%.gif$", ".aseprite"))
local copy = Sprite(sprite)
copy:resize(N*scale, N*scale)
copy:saveAs(out)
print(string.format("OK wrote %s (%d frames, %dx%d @ %dms)", out, #F, copy.width, copy.height, ms))

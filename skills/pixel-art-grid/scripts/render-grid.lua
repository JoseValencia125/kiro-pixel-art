-- render-grid.lua — Render a Pixel Art Bench grid-JSON into a sprite/PNG.
--
-- Input JSON (same schema as AINovice2005/pixel-art-bench-lite):
--   { "grid": [[0,1,1,...],[...], ...],   -- NxN ints 0..9
--     "palette": ["black","#ff0000", ...] -- color per digit index; 0 = first
--   }
-- Index i in the grid selects palette[i+1]. By convention index 0 is background;
-- if its color name is "transparent"/"none"/"bg" it is left transparent.
--
-- Because this Aseprite build does not pass --script-param reliably, the JSON
-- path and output path are read from environment variables:
--   GRID_JSON  = path to the input JSON
--   GRID_OUT   = output image path (.png) or .aseprite
--   GRID_SCALE = integer upscale (default 16)
--
-- Headless:
--   GRID_JSON=in.json GRID_OUT=out.png GRID_SCALE=16 \
--     aseprite -b --script render-grid.lua

local function readfile(path)
  local f = assert(io.open(path, "r"), "cannot open " .. tostring(path))
  local s = f:read("*a"); f:close(); return s
end

-- Minimal JSON parser good enough for this schema (arrays, strings, ints).
local function parse_json(str)
  local i = 1
  local function ws() while i <= #str and str:sub(i,i):match("%s") do i = i + 1 end end
  local value
  local function parse_string()
    assert(str:sub(i,i) == '"'); i = i + 1
    local out = {}
    while i <= #str do
      local c = str:sub(i,i)
      if c == '"' then i = i + 1; break
      elseif c == "\\" then out[#out+1] = str:sub(i+1,i+1); i = i + 2
      else out[#out+1] = c; i = i + 1 end
    end
    return table.concat(out)
  end
  local function parse_number()
    local s = i
    while i <= #str and str:sub(i,i):match("[%-%d%.eE%+]") do i = i + 1 end
    return tonumber(str:sub(s, i-1))
  end
  local function parse_array()
    assert(str:sub(i,i) == "["); i = i + 1; local arr = {}
    ws()
    if str:sub(i,i) == "]" then i = i + 1; return arr end
    while true do
      ws(); arr[#arr+1] = value(); ws()
      local c = str:sub(i,i)
      if c == "," then i = i + 1
      elseif c == "]" then i = i + 1; break
      else error("bad array at " .. i) end
    end
    return arr
  end
  local function parse_object()
    assert(str:sub(i,i) == "{"); i = i + 1; local obj = {}
    ws()
    if str:sub(i,i) == "}" then i = i + 1; return obj end
    while true do
      ws(); local k = parse_string(); ws()
      assert(str:sub(i,i) == ":"); i = i + 1; ws()
      obj[k] = value(); ws()
      local c = str:sub(i,i)
      if c == "," then i = i + 1
      elseif c == "}" then i = i + 1; break
      else error("bad object at " .. i) end
    end
    return obj
  end
  value = function()
    ws(); local c = str:sub(i,i)
    if c == "{" then return parse_object()
    elseif c == "[" then return parse_array()
    elseif c == '"' then return parse_string()
    else return parse_number() end
  end
  return value()
end

-- Resolve a palette entry (name or #hex) to a Color, or nil for transparent.
local NAMED = {
  black=0x000000, white=0xffffff, red=0xff0000, green=0x00a000, blue=0x0000ff,
  yellow=0xffd800, orange=0xff8000, brown=0x8b4513, purple=0x8b4dff,
  pink=0xff77a8, cyan=0x00e4e4, gray=0x808080, grey=0x808080,
  darkgray=0x404040, lightgray=0xc0c0c0, skin=0xffccaa, gold=0xd4af37,
  ["dark green"]=0x1d5b1d, ["light blue"]=0x7ec8ff, ["sky blue"]=0x7ec8ff,
}
local function to_color(name)
  if type(name) ~= "string" then return nil end
  local n = name:lower()
  if n == "transparent" or n == "none" or n == "bg" or n == "background" then return nil end
  if n:sub(1,1) == "#" then
    local hex = n:sub(2)
    if #hex == 3 then hex = hex:gsub("(.)", "%1%1") end
    local r = tonumber(hex:sub(1,2),16) or 0
    local g = tonumber(hex:sub(3,4),16) or 0
    local b = tonumber(hex:sub(5,6),16) or 0
    return Color{ r=r, g=g, b=b }
  end
  local v = NAMED[n]
  if v then return Color{ r=(v>>16)&0xff, g=(v>>8)&0xff, b=v&0xff } end
  -- unknown name: derive a stable color from the string hash (keeps diversity)
  local h = 2166136261
  for k=1,#n do h = (h ~ n:byte(k)) * 16777619 % 0x1000000 end
  return Color{ r=(h>>16)&0xff, g=(h>>8)&0xff, b=h&0xff }
end

local json_path = os.getenv("GRID_JSON")
local out_path  = os.getenv("GRID_OUT") or "grid.png"
local scale     = tonumber(os.getenv("GRID_SCALE") or "16")
assert(json_path, "set GRID_JSON env var")

local data = parse_json(readfile(json_path))
local grid = assert(data.grid, "JSON has no 'grid'")
local palette = data.palette or {}
local H = #grid
local Wc = #grid[1]
assert(H > 0 and Wc > 0, "empty grid")

-- Precompute colors by digit index (0-based -> palette[idx+1])
local colors = {}
for idx = 0, 9 do colors[idx] = to_color(palette[idx + 1]) end

local img = Image(Wc * scale, H * scale)
for y = 1, H do
  local row = grid[y]
  for x = 1, Wc do
    local idx = row[x] or 0
    local col = colors[idx]
    if col then
      for dy = 0, scale - 1 do
        for dx = 0, scale - 1 do
          img:drawPixel((x-1)*scale + dx, (y-1)*scale + dy, col)
        end
      end
    end
  end
end

if app.isUIAvailable == false then
  img:saveAs(out_path)
  print(string.format("wrote %s (%dx%d from %dx%d grid)", out_path, img.width, img.height, Wc, H))
else
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
  app.transaction("grid", function() sprite:newCel(sprite.layers[1], 1).image = img end)
  app.sprite = sprite; app.refresh()
end

-- render-grid.lua — Render a Pixel Art Bench grid-JSON into a sprite/PNG.
--
-- Input JSON (schema from AINovice2005/pixel-art-bench-lite):
--   { "grid": [[0,1,1,...],[...], ...],   -- HxW integer indices (benchmark uses 0..9)
--     "palette": ["black","#ff0000", ...] -- color per digit index; 0 = first
--   }
-- Index i selects palette[i+1] (any i >= 0 the palette covers; >10 colors OK).
-- By convention the BACKGROUND index is 0; set it
-- to a name like "transparent"/"none"/"bg" to leave those cells transparent.
-- Override the background index with env GRID_BG (default 0, "none" to disable).
--
-- This Aseprite build ignores --script-param, so paths come from env vars:
--   GRID_JSON   input JSON path          (required)
--   GRID_OUT    output .png / .aseprite  (default grid.png)
--   GRID_SCALE  integer upscale          (default 16)
--   GRID_BG     background index         (default 0; "none" = nothing transparent)
--   GRID_PREVIEW "1" to print an ASCII preview of the result (default "1")
--
-- Headless:  GRID_JSON=in.json GRID_OUT=out.png aseprite -b --script render-grid.lua
--
-- On validation failure it prints a line beginning with "ERROR:" and exits
-- without writing a file, so callers can detect and fix the grid.

local function fail(msg)
  print("ERROR: " .. msg)
  error(msg, 0)
end

local function readfile(path)
  local f = io.open(path, "r")
  if not f then fail("cannot open " .. tostring(path)) end
  local s = f:read("*a"); f:close(); return s
end

-- ---- minimal JSON parser (arrays, objects, strings, numbers, bool, null) ----
local function parse_json(str)
  local i = 1
  local function ws() while i <= #str and str:sub(i,i):match("%s") do i = i + 1 end end
  local value
  local function parse_string()
    i = i + 1
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
    i = i + 1; local arr = {}; ws()
    if str:sub(i,i) == "]" then i = i + 1; return arr end
    while true do
      ws(); arr[#arr+1] = value(); ws()
      local c = str:sub(i,i)
      if c == "," then i = i + 1 elseif c == "]" then i = i + 1; break
      else fail("bad array near char " .. i) end
    end
    return arr
  end
  local function parse_object()
    i = i + 1; local obj = {}; ws()
    if str:sub(i,i) == "}" then i = i + 1; return obj end
    while true do
      ws(); if str:sub(i,i) ~= '"' then fail("expected key near char " .. i) end
      local k = parse_string(); ws()
      if str:sub(i,i) ~= ":" then fail("expected ':' near char " .. i) end
      i = i + 1; ws(); obj[k] = value(); ws()
      local c = str:sub(i,i)
      if c == "," then i = i + 1 elseif c == "}" then i = i + 1; break
      else fail("bad object near char " .. i) end
    end
    return obj
  end
  value = function()
    ws(); local c = str:sub(i,i)
    if c == "{" then return parse_object()
    elseif c == "[" then return parse_array()
    elseif c == '"' then return parse_string()
    elseif str:sub(i,i+3) == "true" then i = i + 4; return true
    elseif str:sub(i,i+4) == "false" then i = i + 5; return false
    elseif str:sub(i,i+3) == "null" then i = i + 4; return nil
    else local n = parse_number(); if n == nil then fail("bad JSON near char " .. i) end; return n end
  end
  local ok, res = pcall(value)
  if not ok then fail("JSON parse failed: " .. tostring(res)) end
  return res
end

-- ---- expanded named palette (D) ----
local NAMED = {
  black=0x000000, white=0xffffff, gray=0x808080, grey=0x808080,
  darkgray=0x404040, ["dark gray"]=0x404040, lightgray=0xc0c0c0, ["light gray"]=0xc0c0c0,
  silver=0xc0c0c0, charcoal=0x333333,
  red=0xe03030, darkred=0x8b0000, ["dark red"]=0x8b0000, crimson=0xdc143c, maroon=0x800000,
  orange=0xff8000, darkorange=0xcc6600, ["dark orange"]=0xcc6600, amber=0xffbf00,
  yellow=0xffd800, gold=0xd4af37, lemon=0xfff44f,
  green=0x2fae2f, darkgreen=0x1d5b1d, ["dark green"]=0x1d5b1d,
  lightgreen=0x90ee90, ["light green"]=0x90ee90, lime=0x80ff00, olive=0x808000, forest=0x228b22,
  blue=0x2a6bff, darkblue=0x00008b, ["dark blue"]=0x00008b, navy=0x000080,
  lightblue=0x7ec8ff, ["light blue"]=0x7ec8ff, skyblue=0x7ec8ff, ["sky blue"]=0x7ec8ff,
  cyan=0x00e4e4, teal=0x008080, turquoise=0x40e0d0, azure=0x1f9fff,
  purple=0x8b4dff, violet=0x8b4dff, indigo=0x4b0082, magenta=0xff00ff,
  pink=0xff77a8, hotpink=0xff3399, ["hot pink"]=0xff3399, lavender=0xc4b5fd,
  brown=0x8b4513, saddlebrown=0x8b4513, tan=0xd2b48c, beige=0xf5f5dc,
  skin=0xffccaa, ["skin tone"]=0xffccaa, peach=0xffcba4, cream=0xfff8dc,
  ["dark brown"]=0x5a2d0c, wood=0x9b6b43,
  transparent=-1, none=-1, bg=-1, background=-1,
}

local function to_color(name)
  if type(name) ~= "string" then return nil end
  local n = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if n == "" then return nil end
  if n:sub(1,1) == "#" then
    local hex = n:sub(2)
    if #hex == 3 then hex = hex:gsub("(.)", "%1%1") end
    if #hex < 6 then fail("bad hex color: " .. name) end
    return Color{ r = tonumber(hex:sub(1,2),16) or 0,
                  g = tonumber(hex:sub(3,4),16) or 0,
                  b = tonumber(hex:sub(5,6),16) or 0 }
  end
  local v = NAMED[n]
  if v == -1 then return nil end            -- transparent sentinel
  if v then return Color{ r=(v>>16)&0xff, g=(v>>8)&0xff, b=v&0xff } end
  -- unknown: stable hash color (keeps diversity but warn)
  print("WARN: unknown color name '" .. name .. "' -> hashed fallback")
  local h = 2166136261
  for k=1,#n do h = (h ~ n:byte(k)) * 16777619 % 0x1000000 end
  return Color{ r=(h>>16)&0xff, g=(h>>8)&0xff, b=h&0xff }
end

-- ---- read env + parse ----
local json_path = os.getenv("GRID_JSON"); if not json_path then fail("set GRID_JSON env var") end
local out_path  = os.getenv("GRID_OUT") or "grid.png"
local scale     = tonumber(os.getenv("GRID_SCALE") or "16")
local bg_env    = os.getenv("GRID_BG") or "0"
local bg_index  = (bg_env == "none") and -999 or (tonumber(bg_env) or 0)
local do_preview = (os.getenv("GRID_PREVIEW") or "1") ~= "0"

local data = parse_json(readfile(json_path))
if type(data) ~= "table" then fail("top-level JSON must be an object") end
local grid = data.grid; if type(grid) ~= "table" then fail("missing 'grid' array") end
local palette = data.palette or {}

-- ---- strict validation (A) ----
local H = #grid
if H == 0 then fail("grid is empty") end
local Wc = #grid[1]
local max_idx = 0
for y = 1, H do
  local row = grid[y]
  if type(row) ~= "table" then fail("grid row " .. y .. " is not a list") end
  if #row ~= Wc then fail(("ragged grid: row %d has %d cells, expected %d"):format(y, #row, Wc)) end
  for x = 1, Wc do
    local c = row[x]
    if type(c) ~= "number" or c ~= math.floor(c) then fail(("cell (%d,%d) is not an integer: %s"):format(x, y, tostring(c))) end
    if c < 0 then fail(("cell (%d,%d)=%d is negative"):format(x, y, c)) end
    if c > max_idx then max_idx = c end
  end
end
if #palette <= max_idx then
  fail(("palette too short: max index used is %d but palette has %d entries"):format(max_idx, #palette))
end
-- The Pixel Art Bench format uses single digits 0-9 (<=10 colors). We also
-- accept larger integer indices so palettes can exceed 10 colors; any index is
-- valid as long as the palette covers it.

-- ---- resolve colors (for every palette entry, not just 0..9) ----
local colors = {}
for idx = 0, #palette - 1 do colors[idx] = to_color(palette[idx + 1]) end

-- ---- render ----
local img = Image(Wc * scale, H * scale)
for y = 1, H do
  local row = grid[y]
  for x = 1, Wc do
    local idx = row[x]
    local col = colors[idx]
    if idx ~= bg_index and col then
      for dy = 0, scale - 1 do
        for dx = 0, scale - 1 do
          img:drawPixel((x-1)*scale + dx, (y-1)*scale + dy, col)
        end
      end
    end
  end
end

local function write_result()
  if app.isUIAvailable == false then
    img:saveAs(out_path)
    print(string.format("OK wrote %s (%dx%d from %dx%d grid)", out_path, img.width, img.height, Wc, H))
  else
    local sprite = Sprite(img.width, img.height)
    while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
    app.transaction("grid", function() sprite:newCel(sprite.layers[1], 1).image = img end)
    app.sprite = sprite; app.refresh()
  end
end
write_result()

-- ---- ASCII preview of the rendered grid (A) ----
-- Each grid cell -> one char. Background -> '.'; other indices -> their digit.
if do_preview then
  print("PREVIEW " .. Wc .. "x" .. H .. ":")
  for y = 1, H do
    local row = grid[y]
    local line = {}
    for x = 1, Wc do
      local idx = row[x]
      -- single-char cell: bg -> '.', 0-9 -> digit, 10-35 -> a-z, else '+'
      local ch
      if idx == bg_index then ch = "."
      elseif idx <= 9 then ch = tostring(idx)
      elseif idx <= 35 then ch = string.char(string.byte("a") + (idx - 10))
      else ch = "+" end
      line[#line+1] = ch
    end
    print(table.concat(line))
  end
end

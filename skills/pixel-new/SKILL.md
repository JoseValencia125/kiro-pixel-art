---
name: pixel-new
description: Quickly create a new pixel art sprite with optional size and palette presets. Use when the user runs /pixel-new or asks to create a new sprite/canvas with a preset size (icon, small, medium, large, tile, gameboy, nes) or a preset palette (retro, nes, gameboy, c64, cga, snes).
---

## /pixel-new - Quick Sprite Creation

Create a new pixel art sprite with optional presets for size and palette.

Arguments: `$ARGUMENTS` = `[size] [palette]`

### Size presets

- **icon** → 32x32
- **small** → 48x48
- **medium** → 64x64 (default)
- **large** → 128x128
- **tile** → 16x16
- **gameboy** → 160x144
- **nes** → 256x240
- Custom: `WIDTHxHEIGHT` (e.g. `64x64`, `128x96`). Range 1–65535.

### Palette presets

- **retro** (16), **nes** (54), **gameboy** (4: #0f380f,#306230,#8bac0f,#9bbc0f),
  **c64** (16), **cga** (4), **snes** (256), **custom** (prompt for hex colors).
- Default: RGB mode, no palette limit. Retro palettes use Indexed mode.

### Implementation steps for the agent

1. Parse `$ARGUMENTS`: first token = size, second = palette.
2. Map size preset → dimensions, or parse `WxH`. Validate 1–65535.
3. Call `@aseprite/create_canvas` with `width`, `height`, `color_mode`
   (`"RGB"` normally, `"Indexed"` for retro palettes).
4. If a palette was given, call `@aseprite/set_palette` with the color list.
5. Call `@aseprite/get_sprite_info` to confirm, and report size + palette.

### Examples

```
/pixel-new                  → 64x64 RGB canvas
/pixel-new icon             → 32x32 RGB canvas
/pixel-new gameboy gameboy  → 160x144 with Game Boy 4-color palette (indexed)
/pixel-new 128x128 nes      → 128x128 with NES palette
/pixel-new tile retro       → 16x16 with retro 16-color palette
```

### Notes

Tool names map to the MCP server registered in the `pixel-art` agent: the
Claude-style `mcp__aseprite__X` becomes `@aseprite/X` in Kiro.

---
name: pixel-palette
description: Manage sprite color palettes - set a preset or custom palette, optimize/reduce colors, show the current palette, or export it. Use when the user runs /pixel-palette or asks to set/change a palette, reduce colors, apply NES/Game Boy/PICO-8/DawnBringer palettes, or export a .gpl palette file.
---

## /pixel-palette - Palette Management

Manage sprite color palettes with presets, optimization, and custom palettes.

Arguments: `$ARGUMENTS` = `<action> [palette-name|color-count]`

### Actions

- **set** `<preset|custom #hex,#hex,...>` — set palette. Tool: `@aseprite/set_palette`
  (converts sprite to Indexed mode). For retro conversion of existing art prefer
  `@aseprite/quantize_palette` so pixels are remapped, not just the color table.
- **optimize** `<N>` — reduce to N colors (2–256). Tool: `@aseprite/quantize_palette`
  (params: `sprite_path`, `target_colors`, `algorithm`, `dither`,
  `convert_to_indexed`, `preserve_transparency`).
- **show** — display current palette. Tool: `@aseprite/get_palette`
- **export** `<file.gpl>` — write current palette to a GIMP `.gpl` file.

### Presets

Retro consoles: `nes` (54), `gameboy` (4: #0f380f,#306230,#8bac0f,#9bbc0f),
`gameboy-gray`, `c64` (16), `cga` (4), `snes` (256).
Generic: `retro16`, `retro8`, `retro4`, `grayscale4/8/16`.
Modern: `pico8` (16), `sweetie16`, `db16`, `db32`.

PICO-8: `#000000,#1D2B53,#7E2553,#008751,#AB5236,#5F574F,#C2C3C7,#FFF1E8,#FF004D,#FFA300,#FFEC27,#00E436,#29ADFF,#83769C,#FF77A8,#FFCCAA`

DawnBringer 16: `#140c1c,#442434,#30346d,#4e4a4e,#854c30,#346524,#d04648,#757161,#597dce,#d27d2c,#8595a1,#6daa2c,#d2aa99,#6dc2ca,#dad45e,#deeed6`

### Implementation steps for the agent

1. Parse `$ARGUMENTS`: action (first token), then preset name / color count / hex list.
2. **set**: resolve preset → hex list (or parse custom comma-separated hex). Call
   `@aseprite/set_palette`; convert to Indexed mode if needed.
3. **optimize**: validate N∈[2,256]; call `@aseprite/quantize_palette` with
   `target_colors=N`; report before/after.
4. **show**: call `@aseprite/get_palette`; print hex codes + count.
5. **export**: get palette, format as `.gpl`, write with the `write` tool.

### .gpl format

```
GIMP Palette
Name: My Palette
Columns: 4
#
0   0   0   Black
255 255 255 White
```

### Examples

```
/pixel-palette set nes
/pixel-palette set custom #000000,#ffffff,#ff0000
/pixel-palette optimize 16
/pixel-palette show
```

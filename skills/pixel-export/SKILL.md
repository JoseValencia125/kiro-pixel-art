---
name: pixel-export
description: Export the current sprite to PNG, GIF, spritesheet, or JSON metadata with optional scaling and layout. Use when the user runs /pixel-export or asks to export/save/output a sprite to a file, mentions PNG/GIF/spritesheet/JSON, scaling (2x/4x), or game-engine metadata (Unity, Godot, Phaser).
---

## /pixel-export - Quick Export

Export sprites in various formats with optional scaling and layout options.

Arguments: `$ARGUMENTS` = `<format> [output-file] [options]`

### Formats

- **png / gif / jpg / bmp** — single image or animation. Tool: `@aseprite/export_sprite`
  (params: `sprite_path`, `output_path`, `format`, `frame_number`). The output
  format is chosen by `format` / the output file extension; GIF with multiple
  frames produces an animation.
- **sheet** — spritesheet. Tool: `@aseprite/export_spritesheet`
  (params: `sprite_path`, `output_path`, `layout`, `padding`, `include_json`).
- **json** — spritesheet with metadata: call `@aseprite/export_spritesheet` with
  `include_json=true`.

> Note: this pixel-mcp build (v0.5.0) exposes `export_sprite` and
> `export_spritesheet`. There are no separate `export_png` / `export_gif` tools.

### Options (key=value)

- `scale=N` (1,2,4,8; nearest-neighbor, pixel-perfect — apply via scale_sprite if
  the export tool does not take a scale param)
- Sheet: `layout=horizontal|vertical|rows|columns|packed`, `padding=N`,
  `include_json` (JSON metadata)
- `frame_number=N` to export a single frame with `export_sprite`

### Implementation steps for the agent

1. Parse `$ARGUMENTS`: format (first), output path (second, or default), then
   `key=value` options.
2. Call `@aseprite/get_sprite_info` first to validate frames/tags exist.
3. For png/gif/jpg/bmp → `@aseprite/export_sprite` with `format` + `output_path`
   (+ `frame_number` for a single frame).
4. For sheet/json → `@aseprite/export_spritesheet` with `layout`, `padding`, and
   `include_json=true` when JSON metadata is requested.
5. Confirm the created file(s), dimensions, frame count, and (for sheets) layout.

### Defaults if output omitted

png→`sprite.png`, gif→`animation.gif`, sheet→`spritesheet.png`, json→`sprite.json`+`sprite.png`.
Saved to the current working directory unless an absolute path is given.

### Examples

```
/pixel-export png output.png scale=4
/pixel-export gif animation.gif fps=12
/pixel-export sheet spritesheet.png layout=grid
/pixel-export json sprite.json format=unity
```

For deeper guidance (layouts, engine integration, JSON schemas) the
`pixel-art-exporter` skill has full documentation.

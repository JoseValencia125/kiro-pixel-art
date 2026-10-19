---
name: pixel-help
description: Show help for the pixel art tools, commands, and skills (Aseprite + pixel-mcp port). Use when the user runs /pixel-help or asks what pixel art commands/skills are available or how to use them.
---

## /pixel-help - Pixel Art Help

Display help for the Aseprite pixel art tools (ported from willibrandon/pixel-plugin).

Argument (optional): `$ARGUMENTS` = a command or topic name.

### General help (no argument)

```
# Aseprite Pixel Art (Kiro port)

Create, edit, and export pixel art via Aseprite through the pixel-mcp MCP server.
Use the `pixel-art` agent (it registers the @aseprite MCP server).

## Quick start
1. First time: /pixel-setup
2. Create:     /pixel-new 64x64   (or "Create a 32x32 sprite")
3. Edit:       "Draw a red circle", "Add a 4-frame walk cycle"
4. Export:     /pixel-export png sprite.png

## Command skills
/pixel-new [size] [palette]      - Create a new sprite with presets
/pixel-palette <action> [args]   - Manage color palettes
/pixel-export <format> [file]    - Export sprite
/pixel-setup [path]              - Configure pixel-mcp / Aseprite
/pixel-help [topic]              - This help

## Auto-triggered skills (natural language)
pixel-art-creator      - canvas, layers, shapes
pixel-art-animator     - frames, tags, timing, walk/idle/attack cycles
pixel-art-professional - dithering, palette optimization, shading, antialiasing
pixel-art-exporter     - PNG/GIF/spritesheet/JSON for game engines

## Topics
/pixel-help palettes | export | animation | shortcuts
```

### Topic help

- **palettes** → list presets (NES, Game Boy, C64, CGA, SNES, PICO-8, Sweetie16,
  DB16, DB32) and how to apply them via `/pixel-palette set <name>`.
- **export** → formats (png, gif, sheet, json), layouts (horizontal, vertical,
  grid, packed), scaling (1x–8x).
- **animation** → frames, durations, tags, linked cels; common cycles (idle,
  walk, run, jump, attack).
- **shortcuts** → common end-to-end workflows (retro sprite, animated GIF,
  game-engine export).

### Implementation steps for the agent

1. If `$ARGUMENTS` is empty, print the general help above.
2. If it names a command skill (pixel-new, pixel-palette, pixel-export,
   pixel-setup), summarize that skill's usage/examples.
3. If it names a topic (palettes/export/animation/shortcuts), print that section.
4. Otherwise show general help and suggest the closest topic.

### Notes

This is a Kiro port: there is no Claude plugin directory. Skills live in
`~/.kiro/skills/`, the agent in `~/.kiro/agents/pixel-art.json`, the MCP binary
in `~/.local/share/pixel-mcp/bin/pixel-mcp`, and config in
`~/.config/pixel-mcp/config.json`.

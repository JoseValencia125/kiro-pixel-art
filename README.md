# Kiro Pixel Art (Aseprite)

Create, animate, and export **pixel art with Aseprite** directly from
[Kiro CLI](https://kiro.dev), using natural language and slash commands.

This is a **port of [willibrandon/pixel-plugin](https://github.com/willibrandon/pixel-plugin)**
(a Claude Code plugin) to Kiro's agent + skills model. It wires the bundled
[`pixel-mcp`](https://github.com/willibrandon/pixel-plugin) MCP server into a
Kiro agent and ships the four workflow skills plus five slash-command skills.

> Requires [Aseprite](https://www.aseprite.org/) v1.3.0+ installed locally.

## What you get

**Agent** (`pixel-art`) — registers the `pixel-mcp` server as the `@aseprite`
MCP server (50+ Aseprite tools: canvas, layers, drawing, frames, tags, palette
quantization, dithering, shading, spritesheet export, …).

**Workflow skills** (auto-triggered by natural language):

| Skill | Use for |
| --- | --- |
| `pixel-art-creator` | canvas, layers, basic shapes |
| `pixel-art-animator` | frames, tags, timing, walk/idle/attack cycles |
| `pixel-art-professional` | dithering, palette optimization, shading, antialiasing |
| `pixel-art-exporter` | PNG/GIF/spritesheet/JSON for Unity, Godot, Phaser |

**Command skills** (slash commands):

| Command | Description |
| --- | --- |
| `/pixel-new [size] [palette]` | Create a sprite with presets |
| `/pixel-palette <action> [args]` | Set / optimize / show / export palettes |
| `/pixel-export <format> [file]` | Export PNG / GIF / spritesheet / JSON |
| `/pixel-setup [path]` | Configure pixel-mcp + Aseprite |
| `/pixel-help [topic]` | Help |

## Install

```bash
git clone https://github.com/JoseValencia125/kiro-pixel-art.git
cd kiro-pixel-art
./install/install.sh            # auto-detects Aseprite
# or point at a specific binary:
./install/install.sh "/Applications/Aseprite.app/Contents/MacOS/aseprite"
```

The installer:

1. Detects your OS/arch and downloads the matching `pixel-mcp` binary from the
   upstream repo into `~/.local/share/pixel-mcp/bin/`.
2. Detects (or accepts) your Aseprite path and writes
   `~/.config/pixel-mcp/config.json`.
3. Installs the skills into `~/.kiro/skills/` and the agent into
   `~/.kiro/agents/pixel-art.json` (with your paths filled in).
4. Runs a health check.

Supported platforms: macOS (arm64/x86_64) and Linux (arm64/x86_64).

## Usage

```
/agent pixel-art
/pixel-new 64x64 nes
"Create a 32x32 Game Boy character with a 4-frame walk cycle"
/pixel-export sheet spritesheet.png layout=grid
```

## Uninstall

```bash
./install/uninstall.sh
```

## How the port differs from the Claude plugin

- The Claude plugin used `${CLAUDE_PLUGIN_ROOT}` and a Claude marketplace. Here
  the MCP server is registered through a **Kiro agent** (`mcpServers.aseprite`)
  with absolute paths filled in at install time.
- Claude "commands" became **Kiro skills** (slash commands), and skill
  frontmatter was converted to Kiro's format (`name` + `description`,
  `$ARGUMENTS`).
- Tool references were updated to the names actually exposed by `pixel-mcp`
  v0.5.0 (e.g. `export_sprite` / `export_spritesheet` / `quantize_palette`).

## Credits & License

- Upstream plugin and the `pixel-mcp` server: **Brandon Williams**
  ([willibrandon/pixel-plugin](https://github.com/willibrandon/pixel-plugin)),
  MIT License — see [`LICENSE.upstream`](LICENSE.upstream) and [`NOTICE`](NOTICE).
- This Kiro port: MIT License — see [`LICENSE`](LICENSE).

The `pixel-mcp` binary is **not** redistributed in this repo; the installer
downloads it from the upstream repository at install time.

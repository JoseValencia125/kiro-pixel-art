---
name: pixel-setup
description: Configure the pixel-mcp server and verify the Aseprite installation for the pixel-art tools. Use when the user runs /pixel-setup, wants to set up or reconfigure Aseprite, points to an Aseprite path, or pixel art tools are failing because the MCP server or Aseprite path is not configured.
---

## /pixel-setup - Plugin Configuration

Configure the pixel-mcp server and verify Aseprite installation.

Argument (optional): `$ARGUMENTS` = path to the Aseprite executable. If omitted,
auto-detect.

### What this does

1. **Detect Aseprite** (macOS paths, in order):
   - `/Applications/Aseprite.app/Contents/MacOS/aseprite`
   - `$HOME/Applications/Aseprite.app/Contents/MacOS/aseprite`
   - `/usr/local/bin/aseprite`
   - `$HOME/.local/bin/aseprite`
   - Steam: `$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite`
   If `$ARGUMENTS` is a path, use it directly.

2. **Write config** to `~/.config/pixel-mcp/config.json`:
   ```json
   {
     "aseprite_path": "/absolute/path/to/aseprite",
     "temp_dir": "",
     "timeout": 30,
     "log_level": "info",
     "log_file": "",
     "enable_timing": false
   }
   ```
   Only `aseprite_path` is required.

3. **Validate** the path exists and is executable; run `"$ASEPRITE" --version`.

4. **Health check** the MCP server:
   ```bash
   PIXEL_MCP_CONFIG="$HOME/.config/pixel-mcp/config.json" \
     "$HOME/.local/share/pixel-mcp/bin/pixel-mcp" -health
   ```
   Note: the binary uses single-dash flags (`-health`, `-version`, `-debug`).

### Implementation steps for the agent

1. If `$ARGUMENTS` provided, treat it as the Aseprite path; else auto-detect by
   checking the paths above with `test -x`.
2. If none found, tell the user to install Aseprite (https://www.aseprite.org/)
   and stop — do not guess.
3. `mkdir -p ~/.config/pixel-mcp` and write `config.json` (use the `write` tool).
4. Run the health check command above and report the result.
5. Report config file location, resolved Aseprite path + version, and MCP status.

### Success output

```
✓ Aseprite detected at: /Users/you/Applications/Aseprite.app/Contents/MacOS/aseprite
✓ Configuration created: ~/.config/pixel-mcp/config.json
✓ Aseprite version: 1.3.x
✓ MCP server health check passed

Setup complete. Switch to the pixel-art agent and try:
  /pixel-new 64x64
  "Create a 32x32 pixel art character"
```

### Notes

- This port registers the MCP server through the Kiro agent
  `~/.kiro/agents/pixel-art.json` (field `mcpServers.aseprite`), NOT through a
  Claude plugin. The binary lives at `~/.local/share/pixel-mcp/bin/pixel-mcp`.
- Setup only needs to run once; re-run if the Aseprite path changes.
- If health check fails, verify: Aseprite path is correct and executable, and
  the pixel-mcp binary has execute permission (`chmod +x`).

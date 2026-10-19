#!/usr/bin/env bash
#
# install.sh — Install the Kiro pixel-art port (Aseprite + pixel-mcp).
#
# Downloads the pixel-mcp binary from the upstream willibrandon/pixel-plugin
# repo, installs the Kiro agent + skills, writes the pixel-mcp config pointing
# at your Aseprite executable, and runs a health check.
#
# Usage:
#   ./install.sh [path-to-aseprite]
#
# Env overrides:
#   PIXEL_MCP_REF   git ref/branch/tag to fetch the binary from (default: main)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_RAW="https://raw.githubusercontent.com/willibrandon/pixel-plugin"
PIXEL_MCP_REF="${PIXEL_MCP_REF:-main}"

KIRO_SKILLS_DIR="$HOME/.kiro/skills"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
BIN_DIR="$HOME/.local/share/pixel-mcp/bin"
CONFIG_DIR="$HOME/.config/pixel-mcp"
CONFIG_FILE="$CONFIG_DIR/config.json"
BIN_FILE="$BIN_DIR/pixel-mcp"

info() { printf '\033[0;36m•\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# 1. Detect platform and pick the upstream binary asset name
# ---------------------------------------------------------------------------
detect_asset() {
  local os arch
  os="$(uname -s)"; arch="$(uname -m)"
  case "$os" in
    Darwin) case "$arch" in
              arm64) echo "pixel-mcp-darwin-arm64" ;;
              x86_64) echo "pixel-mcp-darwin-amd64" ;;
              *) return 1 ;; esac ;;
    Linux)  case "$arch" in
              aarch64|arm64) echo "pixel-mcp-linux-arm64" ;;
              x86_64) echo "pixel-mcp-linux-amd64" ;;
              *) return 1 ;; esac ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# 2. Detect Aseprite executable (macOS + Linux common paths)
# ---------------------------------------------------------------------------
detect_aseprite() {
  local candidates=(
    "/Applications/Aseprite.app/Contents/MacOS/aseprite"
    "$HOME/Applications/Aseprite.app/Contents/MacOS/aseprite"
    "$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite"
    "/usr/bin/aseprite"
    "/usr/local/bin/aseprite"
    "$HOME/.local/bin/aseprite"
    "/opt/aseprite/bin/aseprite"
    "/snap/bin/aseprite"
  )
  local p
  if command -v aseprite >/dev/null 2>&1; then command -v aseprite; return 0; fi
  for p in "${candidates[@]}"; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

main() {
  local aseprite_path="${1:-}"

  info "Detecting platform..."
  local asset
  if ! asset="$(detect_asset)"; then
    err "Unsupported OS/arch: $(uname -s) $(uname -m). Supported: macOS/Linux x86_64/arm64."
    exit 1
  fi
  ok "Platform asset: $asset"

  # Resolve Aseprite
  if [ -z "$aseprite_path" ]; then
    info "Detecting Aseprite..."
    if ! aseprite_path="$(detect_aseprite)"; then
      err "Aseprite not found. Install it (https://www.aseprite.org/) or pass the path:"
      err "  ./install/install.sh /path/to/aseprite"
      exit 1
    fi
  fi
  [ -x "$aseprite_path" ] || { err "Not executable: $aseprite_path"; exit 1; }
  ok "Aseprite: $aseprite_path"

  # Download binary
  info "Downloading pixel-mcp binary ($asset @ $PIXEL_MCP_REF)..."
  mkdir -p "$BIN_DIR"
  curl -fsSL "$UPSTREAM_RAW/$PIXEL_MCP_REF/bin/$asset" -o "$BIN_FILE"
  chmod +x "$BIN_FILE"
  ok "Installed binary: $BIN_FILE"

  # Write config
  info "Writing config..."
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<JSON
{
  "aseprite_path": "$aseprite_path",
  "temp_dir": "",
  "timeout": 30,
  "log_level": "info",
  "log_file": "",
  "enable_timing": false
}
JSON
  ok "Config: $CONFIG_FILE"

  # Install skills
  info "Installing skills..."
  mkdir -p "$KIRO_SKILLS_DIR"
  cp -R "$REPO_ROOT/skills/"* "$KIRO_SKILLS_DIR/"
  ok "Skills installed to $KIRO_SKILLS_DIR"

  # Install agent with placeholder substitution
  info "Installing agent..."
  mkdir -p "$KIRO_AGENTS_DIR"
  sed -e "s#__PIXEL_MCP_BIN__#$BIN_FILE#g" \
      -e "s#__PIXEL_MCP_CONFIG__#$CONFIG_FILE#g" \
      "$REPO_ROOT/agents/pixel-art.json" > "$KIRO_AGENTS_DIR/pixel-art.json"
  ok "Agent: $KIRO_AGENTS_DIR/pixel-art.json"

  # Health check
  info "Running health check..."
  if PIXEL_MCP_CONFIG="$CONFIG_FILE" "$BIN_FILE" -health; then
    ok "Health check passed."
  else
    err "Health check failed — check the Aseprite path in $CONFIG_FILE"
    exit 1
  fi

  printf '\n'
  ok "Done. In Kiro, switch agents and try it:"
  printf '    /agent pixel-art\n    /pixel-new 64x64\n    "Create a 32x32 Game Boy character with a 4-frame walk cycle"\n'
}

main "$@"

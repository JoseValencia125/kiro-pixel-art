#!/usr/bin/env bash
#
# uninstall.sh — Remove the Kiro pixel-art port.
set -euo pipefail

KIRO_SKILLS_DIR="$HOME/.kiro/skills"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
BIN_DIR="$HOME/.local/share/pixel-mcp"
CONFIG_DIR="$HOME/.config/pixel-mcp"

SKILLS=(pixel-art-creator pixel-art-animator pixel-art-exporter pixel-art-professional
        pixel-new pixel-setup pixel-export pixel-palette pixel-help)

echo "Removing skills..."
for s in "${SKILLS[@]}"; do rm -rf "$KIRO_SKILLS_DIR/$s"; done

echo "Removing agent..."
rm -f "$KIRO_AGENTS_DIR/pixel-art.json"

echo "Removing binary + config..."
rm -rf "$BIN_DIR" "$CONFIG_DIR"

echo "✓ Uninstalled. (Aseprite itself was not touched.)"

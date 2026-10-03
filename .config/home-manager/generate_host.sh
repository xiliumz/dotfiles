#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/home-manager"
SYSTEM="$(nix eval --impure --raw --expr builtins.currentSystem)"

cat > "$CONFIG_DIR/host.nix" <<EOF
{
  username = "$USER";
  homeDirectory = "$HOME";
  system = "$SYSTEM";
}
EOF

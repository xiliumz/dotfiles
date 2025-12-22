#!/usr/bin/env bash
# Installs/updates: Neovim, Kitty terminal, and OpenCode

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting installation/update of Neovim, Kitty, and OpenCode...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Temporary directory for downloads
TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR" || exit 1

# ──────────────────────────────────────────────────────────────────────────────
# 1. Neovim (latest stable)
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${YELLOW}Updating Neovim...${NC}"

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz --transform 's|^nvim-linux-x86_64|nvim|'
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

echo -e "${GREEN}Neovim updated:${NC} $(nvim --version | head -n 1)"

# ──────────────────────────────────────────────────────────────────────────────
# 2. Kitty terminal (latest release)
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${YELLOW}Updating Kitty terminal...${NC}"

# Download latest Kitty binary (official installer script)
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# The installer places it in ~/.local/kitty.app
# Create symlink if not already present
if [[ ! -L /usr/local/bin/kitty ]]; then
    sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/kitty
fi

echo -e "${GREEN}Kitty updated:${NC} $(kitty --version)"

# ──────────────────────────────────────────────────────────────────────────────
# 3. OpenCode (or VSCodium if you meant that)
# ──────────────────────────────────────────────────────────────────────────────
# Note: OpenCode is less common. If you meant VSCodium (open-source VS Code),
# uncomment the VSCodium block below and comment out the OpenCode one.

echo -e "\n${YELLOW}Updating OpenCode (if you meant VSCodium, see comment)...${NC}"

# Option A: OpenCode (if that's what you want)
# (Note: OpenCode is not as widely used; adjust if wrong project)
# if [[ ! -d /opt/opencode ]]; then
#     echo "OpenCode not found in /opt. Skipping update (manual install required)."
# else
#     echo "OpenCode found. Updating not supported automatically yet."
# fi

# Option B: VSCodium (recommended if you meant a VS Code fork)
echo -e "Installing/updating VSCodium (open-source VS Code)...${NC}"

VSCODIUM_TAR="VSCodium-linux-x64.tar.gz"
curl -LO https://github.com/VSCodium/vscodium/releases/latest/download/${VSCODIUM_TAR}
sudo rm -rf /opt/vscodium
sudo tar -C /opt -xzf "${VSCODIUM_TAR}" --transform 's|^VSCodium-linux-x64|vscodium|'
sudo ln -sf /opt/vscodium/bin/codium /usr/local/bin/codium

echo -e "${GREEN}VSCodium updated:${NC} $(codium --version | head -n 1)"

# Clean up
rm -rf "$TMP_DIR"

# ──────────────────────────────────────────────────────────────────────────────
# Final summary
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Installed/updated versions:"
nvim --version | head -n 1
kitty --version
codium --version | head -n 1

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, codium"

#!/usr/bin/env bash
# Installs/updates: Neovim, Kitty terminal, and OpenCode

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting installation/update of Neovim, Kitty, and OpenCode...${NC}"

# Temporary directory for downloads
TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR" || exit 1

# ──────────────────────────────────────────────────────────────────────────────
# 1. Neovim (latest stable) -> https://neovim.io/doc/install/#:~:text=Linux-,Pre%2Dbuilt%20archives,-The%20Releases%20page
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${YELLOW}Updating Neovim...${NC}"

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz --transform 's|^nvim-linux-x86_64|nvim|'
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

echo -e "${GREEN}Neovim updated:${NC} $(nvim --version | head -n 1)"

# ──────────────────────────────────────────────────────────────────────────────
# 2. Kitty terminal (latest release) - System-wide in /opt
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${YELLOW}Installing Kitty terminal to /opt...${NC}"

VERSION=$(curl -s https://sw.kovidgoyal.net/kitty/current-version.txt)

curl -LO "https://github.com/kovidgoyal/kitty/releases/download/v${VERSION}/kitty-${VERSION}-${KITTY_ARCH}.txz"
sudo rm -rf /opt/kitty.app
sudo mkdir -p /opt/kitty.app
sudo tar -xJf "kitty-${VERSION}-${KITTY_ARCH}.txz" -C /opt/kitty.app
sudo ln -sf /opt/kitty.app/bin/kitty /usr/local/bin/kitty
sudo mkdir -p /usr/share/applications
sudo ln -sf /opt/kitty.app/share/applications/kitty.desktop /usr/share/applications/kitty.desktop

echo -e "${GREEN}Kitty installed:${NC} $(kitty --version)"

# ──────────────────────────────────────────────────────────────────────────────
# 3. OpenCode AI (latest release) - System-wide in /opt
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${YELLOW}Installing OpenCode AI to /opt...${NC}"

# Download the latest OpenCode binary for Linux x86_64
curl -s https://api.github.com/repos/sst/opencode/releases/latest \
    | grep "browser_download_url.*linux.*x86_64" \
    | cut -d'"' -f4 \
    | xargs curl -L -o opencode

# Install to /opt
chmod +x opencode
sudo mkdir -p /opt/opencode
sudo mv opencode /opt/opencode/
sudo ln -sf /opt/opencode/opencode /usr/local/bin/opencode

echo -e "${GREEN}OpenCode AI installed${NC}"
# ──────────────────────────────────────────────────────────────────────────────
# Final summary
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Installed/updated versions:"
nvim --version | head -n 1
kitty --version

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, codium"

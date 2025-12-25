#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting installation/update of Neovim, Kitty, and OpenCode...${NC}"

TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    NVIM_ARCH="x86_64"
    KITTY_ARCH="x86_64"
    OPCODE_ARCH="x86_64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_ARCH="arm64"
    KITTY_ARCH="aarch64"
    OPCODE_ARCH="arm64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

# 1. Neovim
echo -e "\n${YELLOW}Updating Neovim...${NC}"
curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz" --transform "s|^nvim-linux-${NVIM_ARCH}|nvim|"
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
echo -e "${GREEN}Neovim updated:${NC} $(nvim --version | head -n 1)"

# 2. Kitty from GitHub releases
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

# 3. OpenCode
echo -e "\n${YELLOW}Installing OpenCode AI to /opt...${NC}"
curl -s https://api.github.com/repos/sst/opencode/releases/latest \
    | grep "browser_download_url.*linux.*${OPCODE_ARCH}" \
    | cut -d'"' -f4 \
    | xargs curl -L -o opencode
chmod +x opencode
sudo mkdir -p /opt/opencode
sudo mv opencode /opt/opencode/
sudo ln -sf /opt/opencode/opencode /usr/local/bin/opencode
echo -e "${GREEN}OpenCode AI installed${NC}"

# Final summary
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Installed/updated versions:"
nvim --version | head -n 1
kitty --version

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, opencode"

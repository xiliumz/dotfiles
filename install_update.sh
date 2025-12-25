#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting installation/update of Neovim, Kitty, and OpenCode...${NC}"

TMP_DIR="$(mktemp -d)"
echo "Created temporary directory: $TMP_DIR"
cd "$TMP_DIR"

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"
if [[ "$ARCH" == "x86_64" ]]; then
    NVIM_ARCH="x86_64"
    KITTY_ARCH="x86_64"
    OPCODE_ARCH="x64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_ARCH="arm64"
    KITTY_ARCH="aarch64"
    OPCODE_ARCH="arm64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

# 1. Neovim
echo -e "\n${YELLOW}Checking Neovim...${NC}"
LATEST_NVIM=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "Latest Neovim version: $LATEST_NVIM"
if command -v nvim >/dev/null 2>&1; then
    CURRENT_NVIM=$(nvim --version | head -n1 | grep -o 'v[0-9.]\+' || echo "unknown")
    echo "Current Neovim version: $CURRENT_NVIM"
else
    CURRENT_NVIM="not installed"
    echo "Neovim: not installed"
fi

if [[ "$CURRENT_NVIM" != "$LATEST_NVIM" ]]; then
    echo -e "${YELLOW}Updating Neovim to $LATEST_NVIM...${NC}"
    echo "Downloading nvim-linux-${NVIM_ARCH}.tar.gz"
    curl -LO "https://github.com/neovim/neovim/releases/download/${LATEST_NVIM}/nvim-linux-${NVIM_ARCH}.tar.gz"
    echo "Removing old /opt/nvim"
    sudo rm -rf /opt/nvim
    echo "Extracting to /opt/nvim"
    sudo tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz" --strip-components=1
    echo "Linking /usr/local/bin/nvim"
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    echo -e "${GREEN}Neovim updated:${NC} $(nvim --version | head -n1)"
else
    echo -e "${GREEN}Neovim already up to date:${NC} $CURRENT_NVIM"
fi

# 2. Kitty
echo -e "\n${YELLOW}Checking Kitty...${NC}"
LATEST_KITTY=$(curl -s https://sw.kovidgoyal.net/kitty/current-version.txt | tr -d '\n')
echo "Latest Kitty version: $LATEST_KITTY"
if command -v kitty >/dev/null 2>&1; then
    CURRENT_KITTY=$(kitty --version | awk '{print $2}')
    echo "Current Kitty version: $CURRENT_KITTY"
else
    CURRENT_KITTY="not installed"
    echo "Kitty: not installed"
fi

if [[ "$CURRENT_KITTY" != "$LATEST_KITTY" ]]; then
    echo -e "${YELLOW}Updating Kitty to $LATEST_KITTY...${NC}"
    echo "Downloading kitty-${LATEST_KITTY}-${KITTY_ARCH}.txz"
    curl -LO "https://github.com/kovidgoyal/kitty/releases/download/v${LATEST_KITTY}/kitty-${LATEST_KITTY}-${KITTY_ARCH}.txz"
    echo "Removing old /opt/kitty.app"
    sudo rm -rf /opt/kitty.app
    echo "Creating /opt/kitty.app"
    sudo mkdir -p /opt/kitty.app
    echo "Extracting to /opt/kitty.app"
    sudo tar -xJf "kitty-${LATEST_KITTY}-${KITTY_ARCH}.txz" -C /opt/kitty.app
    echo "Linking /usr/local/bin/kitty"
    sudo ln -sf /opt/kitty.app/bin/kitty /usr/local/bin/kitty
    echo "Linking desktop file"
    sudo mkdir -p /usr/share/applications
    sudo ln -sf /opt/kitty.app/share/applications/kitty.desktop /usr/share/applications/kitty.desktop
    echo -e "${GREEN}Kitty updated:${NC} $(kitty --version)"
else
    echo -e "${GREEN}Kitty already up to date:${NC} $CURRENT_KITTY"
fi

# 3. OpenCode
echo -e "\n${YELLOW}Checking OpenCode...${NC}"
LATEST_OPENCODE_TAG=$(curl -s https://api.github.com/repos/sst/opencode/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
LATEST_OPENCODE="${LATEST_OPENCODE_TAG#v}"
echo "Latest OpenCode version: $LATEST_OPENCODE"
if command -v opencode >/dev/null 2>&1; then
    CURRENT_OPENCODE=$(opencode --version | awk '{print $1}' || echo "unknown")
    echo "Current OpenCode version: $CURRENT_OPENCODE"
else
    CURRENT_OPENCODE="not installed"
    echo "OpenCode: not installed"
fi

if [[ "$CURRENT_OPENCODE" != "$LATEST_OPENCODE" ]]; then
    echo -e "${YELLOW}Updating OpenCode to $LATEST_OPENCODE...${NC}"
    echo "Downloading opencode-linux-${OPCODE_ARCH}.tar.gz"
    curl -LO "https://github.com/sst/opencode/releases/download/${LATEST_OPENCODE_TAG}/opencode-linux-${OPCODE_ARCH}.tar.gz"
    echo "Extracting archive"
    tar -xzf "opencode-linux-${OPCODE_ARCH}.tar.gz"
    chmod +x opencode
    echo "Creating /opt/opencode"
    sudo mkdir -p /opt/opencode
    echo "Moving binary to /opt/opencode"
    sudo mv opencode /opt/opencode/
    echo "Linking /usr/local/bin/opencode"
    sudo ln -sf /opt/opencode/opencode /usr/local/bin/opencode
    echo -e "${GREEN}OpenCode updated${NC}"
else
    echo -e "${GREEN}OpenCode already up to date:${NC} $CURRENT_OPENCODE"
fi

# Final summary
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Current versions:"
nvim --version | head -n1 2>/dev/null || echo "Neovim: not installed"
kitty --version 2>/dev/null || echo "Kitty: not installed"
opencode --version 2>/dev/null || echo "OpenCode: not installed"

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, opencode"

#!/usr/bin/env bash
set -euo pipefail

# Configuration

INSTALLATION_DIR='/opt'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_json_parser() {
  if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
  else
    HAS_JQ=false
  fi
  if command -v awk >/dev/null 2>&1; then
    HAS_AWK=true
  else
    HAS_AWK=false
  fi
  if ! $HAS_JQ && ! $HAS_AWK; then
    echo -e "${RED}Error: Neither jq nor awk found. At least one is required.${NC}"
    echo "Please install jq: apt-get install jq"
    exit 1
  fi
  if ! $HAS_JQ && $HAS_AWK; then
    echo -e "${YELLOW}Warning: jq not found, using awk fallback for version parsing${NC}"
  fi
}

check_json_parser

get_release_version() {
  local api_url="$1"
  if command -v jq >/dev/null 2>&1; then
    curl -s "$api_url" | jq -r '.tag_name'
  else
    curl -s "$api_url" | awk -F'"' '/tag_name/ {print $4; exit}'
  fi
}

extract_to_installation_dir() {
  if [[ "$1" == "*.txz" ]]; then
    sudo tar --no-same-owner -C "$INSTALLATION_DIR" -xJf "$archive_file"
  else
    sudo tar --no-same-owner -C "$INSTALLATION_DIR" -xzf "$archive_file"
  fi
}

install_or_update() {
  # Parameters
  local name="$1"
  local current_version="$2"
  local latest_version="$3"
  local download_url="$4"
  local binary_path="$5" # Binary path after extraction

  local archive_file="${download_url##*/}"
  local install_path="${binary_path%%*/}" # Get where the binary path is stored. eg: kitty.app/kitty -> kitty.app

  if [[ "$current_version" == "$latest_version" ]]; then
    echo -e "${GREEN}$name already up to date:${NC} $current_version"
    return
  fi

  echo -e "${YELLOW}Updating $name to $latest_version...${NC}"
  echo "Downloading $download_url"
  sudo curl -LO "$download_url"

  echo "Removing old $install_path"
  sudo rm -rf "$install_path"

  echo "Extracting to $INSTALLATION_DIR"
  extract_to_installation_dir "$archive_file"

  echo "Linking $binary_path"
  sudo ln -sf "$INSTALLATION_DIR/$install_path" "/usr/local/bin/"
  echo -e "${GREEN}$name updated:${NC} $latest_version"
}

echo -e "${YELLOW}Starting installation/update...${NC}"

TMP_DIR="$(mktemp -d)"
echo "Created temporary directory: $TMP_DIR"
cd "$TMP_DIR"

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"
if [[ "$ARCH" == "x86_64" ]]; then
    NVIM_ARCH="x86_64"
    KITTY_ARCH="x86_64"
    TMUX_ARCH="x86_64"
    OPCODE_ARCH="x64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_ARCH="arm64"
    KITTY_ARCH="aarch64"
    TMUX_ARCH="arm64"
    OPCODE_ARCH="arm64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

# 1. Neovim
echo -e "\n${YELLOW}Checking Neovim...${NC}"
LATEST_NVIM=$(get_release_version "https://api.github.com/repos/neovim/neovim/releases/latest")
echo "Latest Neovim version: $LATEST_NVIM"
if command -v nvim >/dev/null 2>&1; then
    CURRENT_NVIM=$(nvim --version | head -n1 | grep -o 'v[0-9.]\+' || echo "unknown")
    echo "Current Neovim version: $CURRENT_NVIM"
else
    CURRENT_NVIM="not installed"
    echo "Neovim: not installed"
fi

install_or_update "Neovim" "$CURRENT_NVIM" "$LATEST_NVIM" \
    "https://github.com/neovim/neovim/releases/download/${LATEST_NVIM}/nvim-linux-${NVIM_ARCH}.tar.gz" \
    "nvim-linux-x86_64/bin/nvim"

# 2. Kitty
echo -e "\n${YELLOW}Checking Kitty...${NC}"
LATEST_KITTY=$(get_release_version "https://api.github.com/repos/kovidgoyal/kitty/releases/latest")
LATEST_KITTY="${LATEST_KITTY#v}"
echo "Latest Kitty version: $LATEST_KITTY"
if command -v kitty >/dev/null 2>&1; then
    CURRENT_KITTY=$(kitty --version | awk '{print $2}')
    echo "Current Kitty version: $CURRENT_KITTY"
else
    CURRENT_KITTY="not installed"
    echo "Kitty: not installed"
fi

if [[ "$CURRENT_KITTY" != "$LATEST_KITTY" ]]; then
    install_or_update "Kitty" "$CURRENT_KITTY" "$LATEST_KITTY" \
        "https://github.com/kovidgoyal/kitty/releases/download/v${LATEST_KITTY}/kitty-${LATEST_KITTY}-${KITTY_ARCH}.txz" \
        "kitty.app/bin/kitty"
    echo "Linking desktop file"
    sudo mkdir -p /usr/share/applications
    sudo ln -sf /opt/kitty.app/share/applications/kitty.desktop /usr/share/applications/kitty.desktop
else
    echo -e "${GREEN}Kitty already up to date:${NC} $CURRENT_KITTY"
fi

# 3. tmux
echo -e "\n${YELLOW}Checking tmux...${NC}"
LATEST_TMUX=$(get_release_version "https://api.github.com/repos/tmux/tmux-builds/releases/latest")
echo "Latest tmux version: $LATEST_TMUX"
if command -v tmux >/dev/null 2>&1; then
    CURRENT_TMUX="v$(tmux -V | awk '{print $2}')"
    echo "Current tmux version: $CURRENT_TMUX"
else
    CURRENT_TMUX="not installed"
    echo "tmux: not installed"
fi

TMUX_VERSION="${LATEST_TMUX#v}"
install_or_update "tmux" "$CURRENT_TMUX" "$LATEST_TMUX" \
    "https://github.com/tmux/tmux-builds/releases/download/${LATEST_TMUX}/tmux-${TMUX_VERSION}-linux-${TMUX_ARCH}.tar.gz" \
    "tmux"

# 4. OpenCode
echo -e "\n${YELLOW}Checking OpenCode...${NC}"
LATEST_OPENCODE_TAG=$(get_release_version "https://api.github.com/repos/anomalyco/opencode/releases/latest")
LATEST_OPENCODE="${LATEST_OPENCODE_TAG#v}"
echo "Latest OpenCode version: $LATEST_OPENCODE"
if command -v opencode >/dev/null 2>&1; then
    CURRENT_OPENCODE=$(opencode --version | awk '{print $1}' || echo "unknown")
    echo "Current OpenCode version: $CURRENT_OPENCODE"
else
    CURRENT_OPENCODE="not installed"
    echo "OpenCode: not installed"
fi

install_or_update "OpenCode" "$CURRENT_OPENCODE" "$LATEST_OPENCODE" \
    "https://github.com/anomalyco/opencode/releases/download/${LATEST_OPENCODE_TAG}/opencode-linux-${OPCODE_ARCH}.tar.gz" \
    "opencode"


# Final summary
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Current versions:"
nvim --version | head -n1 2>/dev/null || echo "Neovim: not installed"
kitty --version 2>/dev/null || echo "Kitty: not installed"
opencode --version 2>/dev/null || echo "OpenCode: not installed"
tmux -V 2>/dev/null || echo "tmux: not installed"

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, tmux, opencode"

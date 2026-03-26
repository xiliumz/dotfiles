#!/usr/bin/env bash
set -euo pipefail

# Configuration
INSTALLATION_DIR='/opt'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Tool configuration
NVIM_API_URL="https://api.github.com/repos/neovim/neovim/releases/latest"
NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download"
NVIM_BINARY_PATH="bin/nvim"

KITTY_API_URL="https://api.github.com/repos/kovidgoyal/kitty/releases/latest"
KITTY_DOWNLOAD_URL="https://github.com/kovidgoyal/kitty/releases/download"
KITTY_BINARY_PATH="kitty.app/bin/kitty"
KITTY_DESKTOP_SRC="/opt/kitty.app/share/applications/kitty.desktop"
KITTY_DESKTOP_DST="/usr/share/applications/kitty.desktop"

TMUX_API_URL="https://api.github.com/repos/tmux/tmux-builds/releases/latest"
TMUX_DOWNLOAD_URL="https://github.com/tmux/tmux-builds/releases/download"
TMUX_BINARY_PATH="tmux"

OPENCODE_API_URL="https://api.github.com/repos/anomalyco/opencode/releases/latest"
OPENCODE_DOWNLOAD_URL="https://github.com/anomalyco/opencode/releases/download"
OPENCODE_BINARY_PATH="opencode"

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
  if $HAS_JQ; then
    curl -s "$api_url" | jq -r '.tag_name'
  else
    curl -s "$api_url" | awk -F'"' '/tag_name/ {print $4; exit}'
  fi
}

detect_arch() {
  local arch
  arch=$(uname -m)
  echo "Detected architecture: $arch"
  if [[ "$arch" == "x86_64" ]]; then
    NVIM_ARCH="x86_64"
    KITTY_ARCH="x86_64"
    TMUX_ARCH="x86_64"
    OPCODE_ARCH="x64"
  elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    NVIM_ARCH="arm64"
    KITTY_ARCH="aarch64"
    TMUX_ARCH="arm64"
    OPCODE_ARCH="arm64"
  else
    echo -e "${RED}Unsupported architecture: $arch${NC}"
    exit 1
  fi
}

extract_to_installation_dir() {
  local file="$1"
  local subdir="${2:-}"
  local target="$INSTALLATION_DIR"
  if [[ -n "$subdir" ]]; then
    target="$INSTALLATION_DIR/$subdir"
    sudo mkdir -p "$target"
  fi
  echo "Extracting $file to $target"
  if [[ "$file" == *.txz ]]; then
    sudo tar --no-same-owner -C "$target" -xJf "$TMP_DIR/$file"
  else
    sudo tar --no-same-owner -C "$target" -xzf "$TMP_DIR/$file"
  fi
}

install_or_update() {
  # Parameters
  local name="$1"
  local current_version="$2"
  local latest_version="$3"
  local download_url="$4"
  local binary_path="$5" # Binary path after extraction
  local extract_subdir="${6:-}" # Optional: subdir to extract into (for archives with no root folder)

  local archive_file="${download_url##*/}"
  local install_dir="${binary_path%%/*}" # Top-level dir to remove before extraction. eg: kitty.app/bin/kitty -> kitty.app

  if [[ "$current_version" == "$latest_version" ]]; then
    echo -e "${GREEN}$name already up to date:${NC} $current_version"
    return
  fi

  echo -e "${YELLOW}Updating $name to $latest_version...${NC}"
  echo "Downloading $download_url"
  curl -LO "$download_url"

  echo "Removing old $INSTALLATION_DIR/$install_dir"
  sudo rm -rf "$INSTALLATION_DIR/$install_dir"

  extract_to_installation_dir "$archive_file" "$extract_subdir"
  rm -f "$TMP_DIR/$archive_file"

  echo "Linking $binary_path"
  sudo ln -sf "$INSTALLATION_DIR/$binary_path" "/usr/local/bin/$(basename "$binary_path")"
  echo -e "${GREEN}$name updated:${NC} $latest_version"
}

echo -e "${YELLOW}Starting installation/update...${NC}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
echo "Created temporary directory: $TMP_DIR"
cd "$TMP_DIR"

# Detect architecture
detect_arch

# 1. Neovim
echo -e "\n${YELLOW}Checking Neovim...${NC}"
LATEST_NVIM=$(get_release_version "$NVIM_API_URL")
LATEST_NVIM="${LATEST_NVIM#v}"
echo "Latest Neovim version: $LATEST_NVIM"
if command -v nvim >/dev/null 2>&1; then
    CURRENT_NVIM=$(nvim --version | head -n1 | grep -o '[0-9][0-9.]*' | head -n1 || echo "unknown")
    echo "Current Neovim version: $CURRENT_NVIM"
else
    CURRENT_NVIM="not installed"
    echo "Neovim: not installed"
fi

install_or_update "Neovim" "$CURRENT_NVIM" "$LATEST_NVIM" \
    "${NVIM_DOWNLOAD_URL}/v${LATEST_NVIM}/nvim-linux-${NVIM_ARCH}.tar.gz" \
    "nvim-linux-${NVIM_ARCH}/${NVIM_BINARY_PATH}"

# 2. Kitty
echo -e "\n${YELLOW}Checking Kitty...${NC}"
LATEST_KITTY=$(get_release_version "$KITTY_API_URL")
LATEST_KITTY="${LATEST_KITTY#v}"
echo "Latest Kitty version: $LATEST_KITTY"
if command -v kitty >/dev/null 2>&1; then
    CURRENT_KITTY=$(kitty --version | awk '{print $2}')
    echo "Current Kitty version: $CURRENT_KITTY"
else
    CURRENT_KITTY="not installed"
    echo "Kitty: not installed"
fi

install_or_update "Kitty" "$CURRENT_KITTY" "$LATEST_KITTY" \
    "${KITTY_DOWNLOAD_URL}/v${LATEST_KITTY}/kitty-${LATEST_KITTY}-${KITTY_ARCH}.txz" \
    "$KITTY_BINARY_PATH" \
    "kitty.app"

if [[ "$CURRENT_KITTY" != "$LATEST_KITTY" ]]; then
    echo "Linking desktop file"
    sudo mkdir -p "$(dirname "$KITTY_DESKTOP_DST")"
    sudo ln -sf "$KITTY_DESKTOP_SRC" "$KITTY_DESKTOP_DST"
fi

# 3. tmux
echo -e "\n${YELLOW}Checking tmux...${NC}"
LATEST_TMUX=$(get_release_version "$TMUX_API_URL")
LATEST_TMUX="${LATEST_TMUX#v}"
echo "Latest tmux version: $LATEST_TMUX"
if command -v tmux >/dev/null 2>&1; then
    CURRENT_TMUX=$(tmux -V | awk '{print $2}')
    echo "Current tmux version: $CURRENT_TMUX"
else
    CURRENT_TMUX="not installed"
    echo "tmux: not installed"
fi

install_or_update "tmux" "$CURRENT_TMUX" "$LATEST_TMUX" \
    "${TMUX_DOWNLOAD_URL}/v${LATEST_TMUX}/tmux-${LATEST_TMUX}-linux-${TMUX_ARCH}.tar.gz" \
    "$TMUX_BINARY_PATH"

# 4. OpenCode
echo -e "\n${YELLOW}Checking OpenCode...${NC}"
LATEST_OPENCODE_TAG=$(get_release_version "$OPENCODE_API_URL")
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
    "${OPENCODE_DOWNLOAD_URL}/${LATEST_OPENCODE_TAG}/opencode-linux-${OPCODE_ARCH}.tar.gz" \
    "$OPENCODE_BINARY_PATH"

# Final summary
echo -e "\n${GREEN}Installation/update complete!${NC}"
echo -e "Current versions:"
nvim --version | head -n1 2>/dev/null || echo "Neovim: not installed"
kitty --version 2>/dev/null || echo "Kitty: not installed"
opencode --version 2>/dev/null || echo "OpenCode: not installed"
tmux -V 2>/dev/null || echo "tmux: not installed"

echo -e "\n${YELLOW}Tip:${NC} Run this script anytime to update to the latest versions."
echo -e "You can now use: nvim, kitty, tmux, opencode"

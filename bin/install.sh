#!/usr/bin/env bash
# install.sh — set up the dotfiles on a fresh machine (Linux / macOS / WSL).
#
# Usage:  ./install.sh          (safe default: installs tools + symlinks)
#         ./install.sh --no-tools   (only symlink configs, skip package install)
#         ./install.sh --no-symlinks
#         ./install.sh --all
#
# Safe by default: it never overwrites an existing symlink/target and asks
# before installing packages. Toggle each with --yes.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_TOOLS=1
DO_SYMLINKS=1
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --no-tools) INSTALL_TOOLS=0 ;;
    --no-symlinks) DO_SYMLINKS=0 ;;
    --yes) ASSUME_YES=1 ;;
    --all) INSTALL_TOOLS=1; DO_SYMLINKS=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" == [yY]* ]]
}

os="$(uname -s)"
echo "Detected OS: $os"

# ---------------------------------------------------------------------------
# Symlink configuration files
# ---------------------------------------------------------------------------
link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  ~ skip  $dst (exists)"
  else
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "  ~ linked $src -> $dst"
  fi
}

if [ "$DO_SYMLINKS" -eq 1 ]; then
  echo "==> Linking configs"
  link "$REPO_DIR/shell/.bashrc"   "$HOME/.bashrc"
  link "$REPO_DIR/starship.toml"   "$HOME/.config/starship.toml"
  link "$REPO_DIR/wezterm.lua"     "$HOME/.config/wezterm/wezterm.lua"
  link "$REPO_DIR/nvim"            "$HOME/.config/nvim"
  link "$REPO_DIR/tmux.conf"       "$HOME/.tmux.conf"
fi

# ---------------------------------------------------------------------------
# Package installation per platform
# ---------------------------------------------------------------------------
install_tools() {
  local tools="git curl starship nvim fzf"

  case "$os" in
    Darwin)
      if ! command -v brew >/dev/null; then
        confirm "Homebrew not found. Install it?" && /bin/bash -c \
          "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install $tools
      brew install --cask wezterm
      brew install tmux
      ;;

    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "  (WSL detected)"
      fi
      if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git curl fzf tmux
        # Starship + nvim are newer than apt's copies; prefer the official binaries.
      elif command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm git curl fzf starship neovim tmux
      elif command -v dnf >/dev/null; then
        sudo dnf install -y git curl fzf starship neovim tmux
      fi

      # Starship (official install)
      if ! command -v starship >/dev/null; then
        confirm "Install Starship?" && curl -sS https://starship.rs/install.sh | sh
      fi
      ;;

    *) echo "Unsupported OS for auto-install: $os" ;;
  esac
}

if [ "$INSTALL_TOOLS" -eq 1 ]; then
  echo "==> Installing tools"
  confirm "Install/update tools now?" && install_tools || echo "  skipped"
fi

# ---------------------------------------------------------------------------
# Optional: ble.sh + atuin (not always in package managers)
# ---------------------------------------------------------------------------
if [ "$INSTALL_TOOLS" -eq 1 ]; then
  if [ ! -f "$HOME/.local/share/blesh/ble.sh" ] && confirm "Install ble.sh (bash autosuggestions)?"; then
    curl -fsSL https://raw.githubusercontent.com/akinomyoga/ble.sh/master/install.sh | bash
  fi
  if ! command -v atuin >/dev/null && confirm "Install atuin (fuzzy history)?"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.atuin.sh | sh
  fi
fi

echo
echo "Done. Open a new terminal (or: source ~/.bashrc)."
echo "Recommended fonts: install a Nerd Font (e.g. JetBrainsMono Nerd Font)."

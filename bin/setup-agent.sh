#!/usr/bin/env bash
# setup-agent.sh — bootstrap the "always-on agent" stack on a fresh machine.
#
# Installs:  opencode (the coding agent), Ollama (offline/local brain),
#            a local opencode config + web-server password, and a systemd
#            service so the agent auto-starts and stays alive.
#
# Usage:  ./bin/setup-agent.sh [--no-tool] [--yes] [--serve-http]
#   --no-tool     don't install the tool binaries (opencode / ollama).
#   --yes         don't ask before installing packages.
#   --serve-http  bind opencode web to 0.0.0.0 (needed for Tailscale/phone
#                 access). default is bind to loopback only.
#
# Safe by default: never overwrites existing config, asks before installing.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
ENV_FILE="$CONF_DIR/agent.env"            # secrets: password (0600)
CONFIG_FILE="$CONF_DIR/opencode.json"     # opencode config (provider + server)
SERVICE_FILE="$CONF_DIR/opencode-agent.service"

Y_NO_TOOL=0
ASSUME_YES=0
SERVE_ALL=0

for arg in "$@"; do
  case "$arg" in
    --no-tool) Y_NO_TOOL=1 ;;
    --yes)     ASSUME_YES=1 ;;
    --serve-http) SERVE_ALL=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" == [yY]* ]]
}

os="$(uname -s)"
is_wsl=0
grep -qi microsoft /proc/version 2>/dev/null && is_wsl=1
echo "==> Detected os=$os wsl=$is_wsl"

# ---------------------------------------------------------------------------
# 1. opencode
# ---------------------------------------------------------------------------
install_opencode() {
  if command -v opencode >/dev/null; then
    echo "  ~ opencode already installed: $(opencode --version)"
    return
  fi
  if confirm "Install opencode?"; then
    curl -fsSL https://opencode.ai/install | bash
  fi
}

# ---------------------------------------------------------------------------
# 2. Ollama (offline/local model brain)
# ---------------------------------------------------------------------------
install_ollama() {
  if command -v ollama >/dev/null; then
    echo "  ~ ollama already installed"
    return
  fi
  if confirm "Install Ollama (local models, enables offline use)?"; then
    curl -fsSL https://ollama.com/install.sh | sh || {
      echo "  ! ollama install failed" >&2
      echo "  ! install manually: https://ollama.com/download" >&2
      return
    }
  fi
}

# ---------------------------------------------------------------------------
# 3. server password (only created, never overwritten)
# ---------------------------------------------------------------------------
ensure_password() {
  mkdir -p "$CONF_DIR"
  if [ -f "$ENV_FILE" ]; then
    echo "  ~ using existing password: $ENV_FILE"
    return
  fi
  if confirm "Generate a server password (set OPENCODE_SERVER_PASSWORD)?"; then
    pw="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
    umask 177
    printf 'OPENCODE_SERVER_PASSWORD=%s\nOPENCODE_SERVER_USERNAME=opencode\n' "$pw" > "$ENV_FILE"
    umask 022
    echo "  ~ wrote $ENV_FILE (view it with: cat $ENV_FILE)"
  fi
}

# ---------------------------------------------------------------------------
# 4. opencode config: local Ollama provider + optional network binding
# ---------------------------------------------------------------------------
write_config() {
  mkdir -p "$CONF_DIR"
  if [ -f "$CONFIG_FILE" ]; then
    echo "  ~ existing config kept: $CONFIG_FILE (edit to add local model)"
    return
  fi

  local host="127.0.0.1"
  [ "$SERVE_ALL" -eq 1 ] && host="0.0.0.0"

  cat > "$CONFIG_FILE" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": { "baseURL": "http://${OLLAMA_HOST:-localhost:11434}/v1" },
      "models": {
        "${OLLAMA_MODEL:-qwen3:14b}": { "name": "Local (Ollama)" }
      }
    }
  },
  "server": { "hostname": "$host", "port": 4096 }
}
EOF
  echo "  ~ wrote $CONFIG_FILE (local server: Ollama)"
}
export OLLAMA_HOST="${OLLAMA_HOST:-localhost:11434}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:14b}"

# ---------------------------------------------------------------------------
# 5. systemd service (only on real Linux; skip under WSL unless asked)
# ---------------------------------------------------------------------------
install_service() {
  if [ "$is_wsl" -eq 1 ]; then
    echo "  ~ skipping systemd (WSL) — use 'bin/agent.sh start' with nohup,"
    echo "    or enable systemd in /etc/wsl.conf and re-install --yes"
    return
  fi
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "  ~ no systemd; background control in bin/agent.sh"
    return
  fi

  sed -e "s|ENVFILE|$ENV_FILE|g" -e "s|PORT|4096|g" \
      "$REPO_DIR/shell/opencode-agent.service.tpl" > "$SERVICE_FILE"
  echo "  ~ wrote service unit: $SERVICE_FILE"

  if confirm "Install opencode as a systemd service (auto-start, always alive)?"; then
    sudo install -m 0644 "$SERVICE_FILE" /etc/systemd/system/opencode-agent.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now opencode-agent
    echo "  ~ agent service enabled (status: systemctl status opencode-agent)"
  fi
}

[ "$Y_NO_TOOL" -eq 1 ] || { install_opencode; install_ollama; }
ensure_password
write_config
install_service

echo
echo "==> Agent stack configured."
echo "  Run the server:  bin/agent.sh start"
echo "  Offline model:   ollama pull $OLLAMA_MODEL"
echo "  Test the model:  ollama run $OLLAMA_MODEL \"hi\""
echo "  Then connect from your phone/laptop: http://<this-tailscale-ip>:4096"
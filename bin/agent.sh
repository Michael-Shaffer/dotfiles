#!/usr/bin/env bash
# agent.sh — start / stop / status the opencode web server + optional Ollama.
#
# Usage:  bin/agent.sh start   (loads password from config, starts server in bg)
#         bin/agent.sh stop                ||
#         bin/agent.sh restart||
#         bin/agent.sh status  |
#         bin/agent.sh logs    (tail the log file)
#
# If a systemd service 'opencode-agent' is installed, all commands forward
# to systemctl instead. Otherwise the server runs detached with nohup.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
ENV_FILE="$CONFIG_DIR/agent.env"
LOG_FILE="$CONFIG_DIR/agent.log"
PORT="${OPENCODE_PORT:-4096}"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"

if systemctl --system list-unit-files >/dev/null 2>&1 && \
   systemctl --system list-unit-files | grep -q '^opencode-agent.service'; then
  echo "==> using systemd service"
  case "${1:-status}" in
    start)  sudo systemctl start opencode-agent ;;
    stop)   sudo systemctl stop opencode-agent ;;
    status) sudo systemctl status opencode-agent ;;
    logs)   sudo journalctl -u opencode-agent -f ;;
    *) echo "usage: $0 start|stop|status|logs" ;;
  esac
  exit 0
fi

source_env() {
  [ -f "$ENV_FILE" ] && set -a && . "$ENV_FILE" && set +a
}

case "${1:-status}" in
  start)
    command -v "$OPENCODE_BIN" >/dev/null || { echo "! opencode not installed"; exit 1; }
    if [ -f "$LOG_FILE" ] && pgrep -f "opencode web.*$PORT" >/dev/null; then
      echo "  ~ already running (log: $LOG_FILE)"
      exit 0
    fi
    source_env
    : "${OPENCODE_SERVER_PASSWORD:?set OPENCODE_SERVER_PASSWORD (run setup-agent.sh)}"
    echo "==> starting opencode web on :$PORT (bg)"
    nohup "$OPENCODE_BIN" web --hostname 0.0.0.0 --port "$PORT" \
      >> "$LOG_FILE" 2>&1 &
    echo "  pid $! | log $LOG_FILE"
    echo "  reach at: http://<this-host-tailscale-ip>:$PORT (user: ${OPENCODE_SERVER_USERNAME:-opencode})"
    ;;
  stop)
    if pgrep -f "opencode web.*$PORT" >/dev/null; then
      pkill -f "opencode web.*$PORT"
      echo "  stopped"
    else
      echo "  ~ not running"
    fi
    ;;
  logs)
    tail -f "$LOG_FILE"
    ;;
  status)
    if pgrep -f "opencode web.*$PORT" >/dev/null; then
      echo "  running: opencode web :$PORT"
      echo "  log: $LOG_FILE"
    else
      echo "  not running"
      exit 1
    fi
    ;;
  *) echo "usage: $0 start|stop|status|logs"; exit 1 ;;
esac
#!/usr/bin/env bash
# render.sh — push ai/mcp/servers.json into each MCP client's config.
#
# Usage:
#   ./ai/render.sh                      # render into every client found
#   ./ai/render.sh --dry-run            # show a diff, write nothing
#   ./ai/render.sh --list               # show detected clients and paths
#   ./ai/render.sh --target claude-code # just one client
#   ./ai/render.sh --prune              # also remove servers not defined here
#
# Merges only the `mcpServers` key. Every other key in the target file —
# Claude Desktop's `preferences`, ~/.claude.json's session state — is
# preserved, and the file is backed up before each write.
#
# Quit the client app first. A running Claude Desktop or Claude Code may hold
# the config in memory and write it back out, undoing the render.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_DIR/ai/mcp/servers.json"
RENDERER="$REPO_DIR/ai/lib/render_mcp.py"
ENV_FILE="${MCP_ENV_FILE:-$HOME/.config/dotfiles/mcp.env}"

WANT_TARGET=""
DO_LIST=0
PASSTHRU=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|--prune|--no-backup) PASSTHRU+=("$1") ;;
    --list) DO_LIST=1 ;;
    --target)
      [ -n "${2:-}" ] || { echo "usage: --target <name>"; exit 1; }
      WANT_TARGET="$2"; shift ;;
    --target=*) WANT_TARGET="${1#--target=}" ;;
    # Print the header comment block, stopping at the first line that is not
    # a comment — no line range to keep in sync when the header changes.
    -h|--help)
      awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' \
        "${BASH_SOURCE[0]}"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# Find a Python that actually runs. On Windows, `python3` is often the
# Microsoft Store stub: it exists on PATH and fails when executed.
PY=""
for _cand in "${PYTHON:-}" python3 python py; do
  [ -n "$_cand" ] || continue
  command -v "$_cand" >/dev/null 2>&1 || continue
  if "$_cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)' >/dev/null 2>&1; then
    PY="$_cand"; break
  fi
done
unset _cand
[ -n "$PY" ] || {
  echo "render.sh: no working python3 found (>=3.8)."
  echo "  set PYTHON=/path/to/python if it is installed somewhere unusual."
  exit 1
}

# ---------------------------------------------------------------------------
# Machine-local values
# ---------------------------------------------------------------------------
if [ -f "$ENV_FILE" ]; then
  set -a; . "$ENV_FILE"; set +a
  echo "==> Loaded $ENV_FILE"
else
  echo "==> No $ENV_FILE (using auto-detected defaults only)"
  echo "    cp $REPO_DIR/ai/mcp/mcp.env.example $ENV_FILE && chmod 600 $ENV_FILE"
fi

# Auto-detect anything the env file did not set.
if [ -z "${UV_BIN:-}" ]; then
  UV_BIN="$(command -v uv || true)"
  if [ -z "$UV_BIN" ]; then
    # WinGet's uv, reachable from WSL or Git Bash.
    for _c in "$HOME" /mnt/c/Users/* /c/Users/*; do
      _p="$_c/AppData/Local/Microsoft/WinGet/Packages"
      [ -d "$_p" ] || continue
      _hit="$(find "$_p" -maxdepth 2 -name 'uv.exe' 2>/dev/null | head -1)"
      [ -n "$_hit" ] && { UV_BIN="$_hit"; break; }
    done
    unset _c _p _hit
  fi
fi
# `command -v uv` under Git Bash reports the .exe without its suffix (MSYS
# resolves it transparently, but a Windows app launching that path will not).
case "${UV_BIN:-}" in
  ""|*.exe) ;;
  *) [ -f "$UV_BIN.exe" ] && UV_BIN="$UV_BIN.exe" ;;
esac
export UV_BIN="${UV_BIN:-}"

if [ -z "${MCP_SRC_DIR:-}" ]; then
  for _d in "$HOME/Projects/MCP" /mnt/c/Users/*/Projects/MCP /c/Users/*/Projects/MCP; do
    [ -d "$_d" ] && { MCP_SRC_DIR="$_d"; break; }
  done
  unset _d
fi
export MCP_SRC_DIR="${MCP_SRC_DIR:-}"

# ---------------------------------------------------------------------------
# Where each client keeps its config
# ---------------------------------------------------------------------------
os="$(uname -s)"
is_wsl=0
grep -qi microsoft /proc/version 2>/dev/null && is_wsl=1

# WINHOME: the Windows user dir, seen from WSL.
if [ "$is_wsl" -eq 1 ] && [ -z "${WINHOME:-}" ] && [ -d /mnt/c/Users ]; then
  for _w in /mnt/c/Users/*/; do
    case "$_w" in
      */Public/|*/Default/|*/Default\ User/|*/All\ Users/) ;;
      *) WINHOME="${_w%/}"; break ;;
    esac
  done
  unset _w
fi

desktop_path=""
desktop_winpaths=0
case "$os" in
  Darwin)
    desktop_path="$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
  MINGW*|MSYS*|CYGWIN*)
    # $APPDATA is a native Windows path; normalise the separators so the
    # result reads consistently and file tests behave.
    _appdata="${APPDATA:-$HOME/AppData/Roaming}"
    desktop_path="${_appdata//\\//}/Claude/claude_desktop_config.json"
    unset _appdata
    desktop_winpaths=1 ;;
  Linux)
    if [ "$is_wsl" -eq 1 ] && [ -n "${WINHOME:-}" ]; then
      desktop_path="$WINHOME/AppData/Roaming/Claude/claude_desktop_config.json"
      desktop_winpaths=1
    else
      desktop_path="$HOME/.config/Claude/claude_desktop_config.json"
    fi ;;
esac

# Claude Code reads ~/.claude.json from whichever side it runs on: a Windows
# app on a native Windows host, a Linux one under WSL.
code_winpaths=0
case "$os" in MINGW*|MSYS*|CYGWIN*) code_winpaths=1 ;; esac

# name|path|needs-windows-paths
TARGETS=()
[ -n "$desktop_path" ] && TARGETS+=("claude-desktop|$desktop_path|$desktop_winpaths")
TARGETS+=("claude-code|$HOME/.claude.json|$code_winpaths")

if [ "$DO_LIST" -eq 1 ]; then
  echo "==> Values"
  printf '    %-22s %s\n' "UV_BIN" "${UV_BIN:-(unset)}"
  printf '    %-22s %s\n' "MCP_SRC_DIR" "${MCP_SRC_DIR:-(unset)}"
  printf '    %-22s %s\n' "OBSIDIAN_VAULT_PATH" "${OBSIDIAN_VAULT_PATH:-(unset)}"
  echo "==> Clients"
  for t in "${TARGETS[@]}"; do
    IFS='|' read -r name path win <<<"$t"
    if [ -f "$path" ]; then state="present"; else state="absent"; fi
    printf '    %-16s %-8s %s\n' "$name" "$state" "$path"
  done
  exit 0
fi

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
echo "==> Rendering MCP servers"
rendered_any=0

for t in "${TARGETS[@]}"; do
  IFS='|' read -r name path win <<<"$t"

  if [ -n "$WANT_TARGET" ] && [ "$WANT_TARGET" != "$name" ]; then continue; fi

  # Only touch a client that is actually installed, unless asked by name.
  if [ ! -f "$path" ] && [ -z "$WANT_TARGET" ]; then
    echo "  - skip $name (not installed)"
    continue
  fi

  args=(--template "$TEMPLATE" --target "$path")
  [ "$win" -eq 1 ] && args+=(--windows-paths)

  echo "  → $name"
  "$PY" "$RENDERER" "${args[@]}" "${PASSTHRU[@]+"${PASSTHRU[@]}"}"
  rendered_any=1
done

if [ "$rendered_any" -eq 0 ]; then
  echo "  no matching client found${WANT_TARGET:+ for '$WANT_TARGET'}"
  exit 1
fi

echo
echo "Restart the client app to pick up the change."

# agentrc.sh — machine-specific / per-user shell additions.
#
# This file is SOURCED from a single line at the end of ~/.bashrc (the repo's
# portable config). Keeping these here means:
#   - ~/.bashrc stays portable and identical on every machine.
#   - Adding or updating tools never clobbers anything a user already had in
#     their own ~/.bashrc or PATH.
#   - A fresh machine (or someone else's) degrades gracefully: every entry
#     below only applies if the tool actually exists.
#
# Symlinked from the dotfiles repo to ~/.agentrc by install.sh.

# -- PATH helpers (append only if the dir exists; never clobber) -----------
__path_append() {
  local d
  for d in "$@"; do
    case ":$PATH:" in
      *":$d:"*) ;;                       # already present
      *) [ -d "$d" ] && export PATH="$d:$PATH" ;;
    esac
  done
}

# Local user binaries (pipx / cargo / npm global style installs)
__path_append "$HOME/.local/bin"

# opencode agent
__path_append "$HOME/.opencode/bin"

# kimi-code agent (if installed)
__path_append "$HOME/.kimi-code/bin"

# -- Windows / WSL host conveniences ---------------------------------------
# WINHOME: first user dir under the Windows mount, if any.
if [ -d /mnt/c/Users ] && [ -z "${WINHOME:-}" ]; then
  for _w in /mnt/c/Users/*/; do
    case "$_w" in
      */Public/|*/Default/|*/Default\ User/|*/All\ Users/) ;;
      *) WINHOME="$_w"; break ;;
    esac
  done
  export WINHOME
  unset _w
fi

# Obsidian CLI on the Windows host.
command -v obsidian.exe >/dev/null 2>&1 && alias obsidian="obsidian.exe"

# -- claude / cl wrappers (only if the base binary exists) -----------------
__claude="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
if [ -x "$__claude" ]; then
  claude() { CLAUDE_CONFIG_DIR="$HOME/.claude-pro" command "$__claude" "$@"; }
  cl()     { CLAUDE_CONFIG_DIR="$HOME/.claude-max" command "$__claude" "$@"; }
fi
unset __claude

# -- personal, untracked overlay (edit freely; survives every re-install) --
[ -f "$HOME/.agentrc.local" ] && . "$HOME/.agentrc.local"

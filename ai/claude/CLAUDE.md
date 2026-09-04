# Global instructions

Applies to every Claude Code session on this machine. Project-level `CLAUDE.md`
files override anything here.

## Environment

- Primary machine is Windows 11 with WSL2 (RHEL 9.4 default, Ubuntu 22.04).
  Shell scripts target bash; the Windows side runs PowerShell. Check which side
  a path lives on before assuming a separator.
- Dotfiles live in `~/Projects/Workflow` and are symlinked into `$HOME` by
  `bin/install.sh`. Editing `~/.bashrc` edits the repo — commit the change.
- Machine-specific shell settings belong in `~/.agentrc.local` (untracked), not
  in the tracked `shell/.bashrc`.

## Working style

- Match the conventions already in the file over any general style preference.
- Shell scripts here are `set -euo pipefail`, POSIX-ish bash, commented at the
  top with a usage block. Follow that shape.
- Don't add a dependency to make a small thing shorter.

## Boundaries

- Never write a credential into a tracked file. Secrets go in
  `~/.config/dotfiles/mcp.env` or `~/.agentrc.local`, both untracked and 600.
- Don't commit or push unless asked.

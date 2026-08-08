#!/usr/bin/env bash
# diagnose-prompt.sh — figure out why the prompt looks broken.
#
# Run this inside the broken shell, then read the output. It prints which
# prompt engines are active, whether you're in tmux, the actual PS1 that's
# set, and whether wide (Nerd Font) glyphs render as one column or overlap.

printf '\n%-28s %s\n' "VARIABLE" "VALUE"
printf '%-28s %s\n' "TERM" "${TERM:-unset}"
printf '%-28s %s\n' "SHLVL" "${SHLVL:-unset}"
printf '%-28s %s\n' "TMUX" "${TMUX:-not-in-tmux}"
printf '%-28s %s\n' "STARSHIP_SHELL" "${STARSHIP_SHELL:-not-set}"
printf '%-28s %s\n' "starship on PATH" "$(command -v starship || echo missing)"
printf '%-28s %s\n' "ble.sh enabled in bashrc" "$(grep -q 'blesh/ble.sh' "$HOME/.bashrc" && echo yes || echo no)"
printf '%-28s %s\n' "SHELL" "${SHELL:-unset}"

echo
echo "PROMPT_COMMAND: ${PROMPT_COMMAND:-<empty>}"

echo
echo "PS1 (as bash sees it):"
printf '  %q\n' "${PS1:-<empty>}"

echo
echo "Wide-glyph render check (should look like ONE arrow after the colon):"
# Two Nerd-Font arrows. If this shows two ^M-wrap or the colon wraps oddly,
# or if width is mis-counted, it's a wide-glyph / TERM issue (tmux).
printf '  A \uf078\uf078 : <- these\n'
echo "  <- 'esac' that look like boxes = missing Nerd Font in the terminal."

echo
echo "Locale:"
locale 2>/dev/null || true

echo
echo "tmux default-terminal (if in tmux):"
tmux show-options -g default-terminal 2>/dev/null || true

echo
echo "Quick fix menu:"
echo "  - No theme at all   -> ensure 'eval \"\$(starship init bash)\"' is in ~/.bashrc"
echo "  - Tofu boxes         -> install a Nerd Font in the *terminal* (WezTerm font line)"
echo "  - Overlap/duplicate  -> only ONE of starship / ble.sh may be enabled"
echo "  - In tmux:           -> 'set -g default-terminal tmux-256color' in ~/.tmux.conf"
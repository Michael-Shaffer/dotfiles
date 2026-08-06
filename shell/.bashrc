# ~/.bashrc — sourced for interactive bash.
# Lives in the dotfiles repo; symlinked to ~/.bashrc by install.sh.
# Adds fish-like autosuggestions (ble.sh), fuzzy history (atuin), a rich
# prompt (Starship), and modern tab-completion.

# --- Global settings -------------------------------------------------------
HISTSIZE=5000
HISTFILESIZE=10000
export EDITOR="nvim"
export VISUAL="nvim"

# --- ble.sh: autosuggestions + syntax highlighting for bash ------------------
# https://github.com/akinomyoga/ble.sh
# Install once: curl -fsSL https://sh.rustup.rs/... (see README) or the repo's
# install script. It is sourced only when the tool is actually installed.
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
  source "$HOME/.local/share/blesh/ble.sh" --noattach
  bleopt prompt_ruler_margin=''
  # fish-style autosuggestion ghost text
  bleopt exec_errexit_mark=''
  ble-syntax/colorize on
fi

# --- bash-completion (tab completion for most commands) ----------------------
if [ -f /usr/share/bash-completion/bash_completion ]; then
  source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# --- Starship prompt --------------------------------------------------------
# https://starship.rs — same prompt on every shell/OS.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# --- atuin: replace ctrl-r with fuzzy history --------------------------------
# https://atuin.sh
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init bash)"
fi

# --- fzf: fuzzy file/command search, ctrl-t ---------------------------------
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash 2>/dev/null || true)"
fi

# --- Convenience aliases -----------------------------------------------------
alias ls="ls --color=auto" 2>/dev/null
alias ll="ls -lah"
alias la="ls -la"
alias l="ls -lF"
alias ..="cd .."
alias ...="cd ../.."
alias gs="git status"
alias gd="git diff"
alias gp="git pull"
alias gc="git commit"
alias gcm="git commit -m"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# --- Less-friendly commands ---------------------------------------------
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# Ensure we don't log secrets.
unset HISTIGNORE

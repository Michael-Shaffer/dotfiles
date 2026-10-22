# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ---------------------------------------------------------------------------
# ble.sh — syntax highlighting + fish-style autosuggestions.
#
# Must be sourced HERE, before anything touches the prompt, but with
# --noattach so it doesn't take over yet. The matching ble-attach runs at the
# very bottom, after Starship has installed its hooks.
#
# Order is the whole trick. Sourcing ble.sh at the bottom (or attaching early)
# makes Starship and ble.sh both draw PS1 — a duplicated prompt with wide
# Nerd Font glyphs double-counted. With --noattach here and ble-attach last,
# they coexist: Starship owns the prompt, ble.sh owns the editing line.
# ---------------------------------------------------------------------------
[ -f "$HOME/.local/share/blesh/ble.sh" ] && \
    source "$HOME/.local/share/blesh/ble.sh" --noattach

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export PATH="$HOME/.local/bin:$PATH"

# WSL appends every folder on the Windows PATH (41 here, some listed three
# times). ble.sh looks the typed command up across all of them on Enter, and
# each lookup into /mnt/c is slow: ~350ms before ANY command's output showed.
# Keep only the Windows tools used from Linux (clip.exe/cmd.exe, explorer.exe,
# powershell.exe, code, cursor, obsidian.exe for .agentrc) and drop duplicates.
# Anything else on the Windows side still runs by its full /mnt/c path.
if [ -n "${WSL_DISTRO_NAME-}" ]; then
    _path=
    IFS=: read -ra _dirs <<< "$PATH"
    for _d in "${_dirs[@]}"; do
        case $_d in
            /mnt/[a-z]/*)
                case ${_d,,} in
                    */windows|*/windows/system32|*/windowspowershell/v1.0) ;;
                    */microsoft\ vs\ code/bin|*/cursor/resources/app/bin|*/programs/obsidian) ;;
                    *) continue ;;
                esac ;;
        esac
        case :$_path: in *:"$_d":*) continue ;; esac
        _path=${_path:+$_path:}$_d
    done
    PATH=$_path
    unset _path _dirs _d

    # Open links (gh auth login, etc.) in the Windows default browser. WSL
    # has no Linux browser; wslview (apt package wslu) hands the URL over.
    export BROWSER=wslview
fi

# No "did you mean to install..." lookup on a mistyped command. Ubuntu's
# command-not-found (and RHEL's PackageKit equivalent) start a package search
# that took ~0.8s per typo under WSL; plain bash prints its own one-line
# "command not found" once the handler is gone.
unset -f command_not_found_handle

# Shortened file paths (WSL2 paths can get gangly)
PROMPT_DIRTRIM=2

# ---------------------------------------------------------------------------
# Per-machine / per-user additions (tool PATHs, WINHOME, claude wrappers,
# obsidian alias). Kept in a SEPARATE file so this .bashrc stays portable and
# never clobbers anything a machine already had set. Source it if present.
# ---------------------------------------------------------------------------
[ -f "$HOME/.agentrc" ] && . "$HOME/.agentrc"

# ---------------------------------------------------------------------------
# Prompt: Starship.
# ---------------------------------------------------------------------------
if [ -x "$(command -v starship)" ]; then
    eval "$(starship init bash)"
fi

# ---------------------------------------------------------------------------
# Blank line BETWEEN command blocks, but not above the first prompt on a fresh
# or just-cleared screen.
#
# Starship's own add_newline can't do this — it has no state between prompts,
# so it's all prompts or none (it's set to false in starship.toml for exactly
# this reason). The rule we want is really "separate me from the previous
# command's output", and on a clean screen there is no previous output.
#
# Ctrl-L and `clear` reset the flag so a cleared screen starts flush at the top.
# ---------------------------------------------------------------------------
__prompt_gap() {
    [ -n "${__PROMPT_GAP_ARMED-}" ] && printf '\n'
    __PROMPT_GAP_ARMED=1
}

# Tell the terminal which folder the shell is in (OSC 7). WezTerm opens new
# tabs there and names the tab after it; without this it only knew the
# Windows folder it was launched from, so new tabs landed in /mnt/c/Users/...
__osc7_cwd() {
    printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "${PWD// /%20}"
}

__precmd() {
    __prompt_gap
    __osc7_cwd
}
# Hook via starship_precmd_user_func, NOT PROMPT_COMMAND. Starship's own init
# warns that appending to PROMPT_COMMAND breaks exit-status ($?) checking and
# prepending breaks the cmd_duration module; this hook is called from inside
# starship_precmd at the right moment, after $? is restored and before PS1 is
# built, so it sidesteps both.
starship_precmd_user_func="__precmd"

# `clear` as a function so it resets the flag too; `command clear` still works.
clear() { command clear "$@"; unset __PROMPT_GAP_ARMED; }

# Ctrl-L bypasses the `clear` function above, so it needs the flag reset too.
# ble.sh owns the keymap when loaded, so wrap its clear-screen widget; plain
# readline otherwise.
if [[ ${BLE_VERSION-} ]]; then
    ble/widget/gap-clear-screen() {
        unset __PROMPT_GAP_ARMED
        ble/widget/clear-screen
    }
    ble-bind -f 'C-l' 'gap-clear-screen'
else
    bind -x '"\C-l": clear' 2>/dev/null
fi

# ---------------------------------------------------------------------------
# Attach ble.sh LAST, once Starship's prompt hooks are installed. Pairs with
# the --noattach source at the top of this file; see the note there for why
# the order matters.
# ---------------------------------------------------------------------------
# ble.sh takes PROMPT_COMMAND over entirely — it unsets the real variable and
# runs a stashed copy from inside its own prompt cycle — and it draws the first
# prompt without that pass. So __prompt_gap first runs before prompt TWO, which
# then gets treated as the first prompt and every gap lands one prompt late.
# Arming here spends that allowance on the prompt ble.sh already drew. Plain
# bash runs PROMPT_COMMAND before its first prompt, so it needs no help.
if [[ ${BLE_VERSION-} ]]; then
    # Autosuggestions as dim ghost text. ble.sh's default face (fg=238,bg=254)
    # is built for light terminals and shows as a bright grey box on Kanagawa;
    # colour 8 is the palette's bright-black, so this follows the theme. The
    # delay stops suggestions flickering in and out while typing.
    ble-face auto_complete=fg=8
    bleopt complete_auto_delay=300

    # No syntax colouring of the command line. Its defaults put unknown
    # commands (and half-typed ones, until the word is finished) on a solid
    # red background and coloured builtins red, so it read as a spell checker
    # nagging mid-word. ble.sh still provides suggestions and completion.
    bleopt highlight_syntax=

    ble-attach
    __PROMPT_GAP_ARMED=1
fi

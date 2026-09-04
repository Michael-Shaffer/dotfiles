-- WezTerm configuration
-- https://wezfurlong.org/wezterm/config/lua.html
--
-- Cross-OS setup: this file lives in the dotfiles repo and is symlinked to
-- ~/.config/wezterm/wezterm.lua (Linux/WSL) or %USERPROFILE%\.config\wezterm\wezterm.lua (Windows).

local wezterm = require("wezterm")
local config = {}

-- ---------------------------------------------------------------------------
-- Fonts
-- ---------------------------------------------------------------------------
-- Red Hat Mono for text; JetBrainsMono Nerd Font supplies the icon glyphs
-- (Starship symbols, etc.) that Red Hat Mono doesn't include. The Nerd Font is
-- only used as a fallback for missing glyphs, so text stays Red Hat Mono.
config.font = wezterm.font_with_fallback({
  { family = "Red Hat Mono", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
  { family = "JetBrainsMono NF" },
})
config.font_size = 12.0
config.line_height = 1.1

-- ---------------------------------------------------------------------------
-- Appearance / color scheme
-- ---------------------------------------------------------------------------
-- Hacker-style green-on-black, tuned to opencode's "matrix" theme.
config.window_background_opacity = 0.95
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE" -- or "TITLE | RESIZE" for a native title bar
config.colors = {
  foreground = "#62ff94",
  background = "#0a0e0a",
  cursor_bg = "#2eff6a",
  cursor_fg = "#0a0e0a",
  cursor_border = "#2eff6a",
  selection_bg = "#1cc24b",
  selection_fg = "#0a0e0a",
  split = "#1cc24b",
  ansi = {
    "#0a0e0a", -- black
    "#ff4b4b", -- red
    "#1cc24b", -- green
    "#e6ff57", -- yellow
    "#30b3ff", -- blue
    "#c770ff", -- magenta
    "#24f6d9", -- cyan
    "#62ff94", -- white
  },
  brights = {
    "#8ca391", -- bright black
    "#ff7171", -- bright red
    "#2eff6a", -- bright green
    "#e6ff57", -- bright yellow
    "#30b3ff", -- bright blue
    "#c770ff", -- bright magenta
    "#24f6d9", -- bright cyan
    "#eef3ea", -- bright white
  },
}

-- ---------------------------------------------------------------------------
-- Window / tabs / cursor
-- ---------------------------------------------------------------------------
config.enable_tab_bar = true
-- With integrated buttons the tab bar doubles as the title bar / drag handle,
-- so it must stay visible or the window can't be dragged (drag from empty
-- space in the bar; Ctrl-Shift-drag also works).
config.hide_tab_bar_if_only_one_tab = false
config.colors.tab_bar = {
  active_tab = { bg_color = "#2eff6a", fg_color = "#0a0e0a" },
  inactive_tab = { bg_color = "#0a0e0a", fg_color = "#8ca391" },
  inactive_tab_hover = { bg_color = "#0a0e0a", fg_color = "#2eff6a" },
}
config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBlock"

-- ---------------------------------------------------------------------------
-- Practical bits
-- ---------------------------------------------------------------------------
config.scrollback_lines = 10000
config.audible_bell = "Disabled" -- no beep

-- No `copy_on_select` option exists in WezTerm; setting one is a hard config
-- error. Selecting already copies: WezTerm's default binding completes the
-- selection on mouse-up, and the Shift bindings below send it to the OS
-- clipboard explicitly. Unmodified drags go to tmux, which pipes to clip.exe
-- (see tmux.conf), so both paths land on the Windows clipboard anyway.

-- Shift+click / Shift+drag selects natively in WezTerm instead of letting
-- tmux (which has `set -g mouse on`) swallow the mouse. tmux forwards its own
-- selections to the OS clipboard via OSC-52, so both paths end up on the
-- Windows clipboard.
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "SHIFT",
    action = wezterm.action.ExtendSelectionToMouseCursor("Cell"),
  },
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "SHIFT",
    action = wezterm.action.ExtendSelectionToMouseCursor("Cell"),
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "SHIFT",
    action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
  },
}

-- OSC-52 clipboard (write) is enabled by default, so nvim copy works with the OS.

-- Windows-standard copy/paste keys (Ctrl+Insert / Shift+Insert) alongside the
-- built-in Ctrl+Shift+C / Ctrl+Shift+V, so muscle memory just works.
config.keys = {
  { key = "Insert", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
  { key = "Insert", mods = "SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
}

-- ---------------------------------------------------------------------------
-- Launch: default shell
-- ---------------------------------------------------------------------------
-- The terminal window runs on Windows, but we launch the Linux shell inside
-- WSL so the whole dev environment (bash, starship, tmux, nvim) is Linux.
-- Change the `-d` distro name when switching distros (e.g. ArchWSL).
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { "wsl.exe", "-d", "Ubuntu-22.04", "--cd", "~", "--", "bash", "-l" }
end

return config

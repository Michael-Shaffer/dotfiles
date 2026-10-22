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
-- Red Hat Mono is a touch tight vertically; 1.2 reads like a page, not a grid.
config.line_height = 1.2

-- ---------------------------------------------------------------------------
-- Appearance / color scheme
-- ---------------------------------------------------------------------------
-- Kanagawa (wave), from rebelot/kanagawa.nvim's WezTerm extra: ink-wash
-- background, parchment text. Spelled out rather than `config.color_scheme`
-- so the hexes are greppable when tmux / Starship need to match them.
-- Starship and dircolors use ANSI colour NAMES, so they follow this table.
config.window_background_opacity = 0.95
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE" -- or "TITLE | RESIZE" for a native title bar
config.window_padding = { left = 16, right = 16, top = 12, bottom = 8 }
config.colors = {
  foreground = "#dcd7ba", -- fujiWhite
  background = "#1f1f28", -- sumiInk3
  cursor_bg = "#c8c093",
  cursor_fg = "#1f1f28",
  cursor_border = "#c8c093",
  selection_bg = "#2d4f67", -- waveBlue2
  selection_fg = "#c8c093",
  scrollbar_thumb = "#16161d",
  split = "#54546d", -- sumiInk6
  ansi = {
    "#090618", -- black
    "#c34043", -- red      autumnRed
    "#76946a", -- green    autumnGreen
    "#c0a36e", -- yellow   boatYellow2
    "#7e9cd8", -- blue     crystalBlue
    "#957fb8", -- magenta  oniViolet
    "#6a9589", -- cyan     waveAqua1
    "#c8c093", -- white    oldWhite
  },
  brights = {
    "#727169", -- bright black    fujiGray
    "#e82424", -- bright red      samuraiRed
    "#98bb6c", -- bright green    springGreen
    "#e6c384", -- bright yellow   carpYellow
    "#7fb4ca", -- bright blue     springBlue
    "#938aa9", -- bright magenta  springViolet1
    "#7aa89f", -- bright cyan     waveAqua2
    "#dcd7ba", -- bright white    fujiWhite
  },
  indexed = { [16] = "#ffa066", [17] = "#ff5d62" },
}

-- ---------------------------------------------------------------------------
-- Window / tabs / cursor
-- ---------------------------------------------------------------------------
config.enable_tab_bar = true
-- With integrated buttons the tab bar doubles as the title bar / drag handle,
-- so it must stay visible or the window can't be dragged (drag from empty
-- space in the bar; Ctrl-Shift-drag also works).
config.hide_tab_bar_if_only_one_tab = false
-- Flat "retro" bar so it takes the palette below instead of the stock
-- gradient. The active tab is marked by colour, not a bright block.
config.use_fancy_tab_bar = false
config.tab_max_width = 28
config.colors.tab_bar = {
  background = "#16161d", -- sumiInk0
  active_tab = { bg_color = "#2a2a37", fg_color = "#e6c384", intensity = "Bold" },
  inactive_tab = { bg_color = "#16161d", fg_color = "#727169" },
  inactive_tab_hover = { bg_color = "#223249", fg_color = "#dcd7ba" },
  new_tab = { bg_color = "#16161d", fg_color = "#727169" },
  new_tab_hover = { bg_color = "#223249", fg_color = "#dcd7ba" },
}
-- Unfocused splits fade back so the active one is obvious.
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }
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
  -- Pick which distro to open a tab in, without touching this file.
  {
    key = "d",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|DOMAINS" }),
  },
}

-- ---------------------------------------------------------------------------
-- Launch: WSL distros as domains
-- ---------------------------------------------------------------------------
-- The terminal window runs on Windows, but the shell lives in WSL so the whole
-- dev environment (bash, starship, tmux, nvim) is Linux.
--
-- Every installed distro is registered as its own domain rather than hardcoding
-- one in default_prog. Install a new distro and it appears in the tab-bar "+"
-- dropdown and the launcher with no edit here — only DEFAULT_DISTRO below picks
-- which one a plain new tab opens.
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  local DEFAULT_DISTRO = "Ubuntu-22.04"

  local domains = wezterm.default_wsl_domains()
  for _, dom in ipairs(domains) do
    dom.default_cwd = "~"
  end
  config.wsl_domains = domains
  config.default_domain = "WSL:" .. DEFAULT_DISTRO
end

return config

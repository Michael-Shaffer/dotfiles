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
config.font = wezterm.font({
  family = "JetBrainsMono Nerd Font",
  harfbuzz_features = { "calt=1", "clig=1", "liga=1" }, -- ligatures
})
config.font_size = 12.0
config.line_height = 1.1

-- ---------------------------------------------------------------------------
-- Appearance / color scheme (Catppuccin)
-- ---------------------------------------------------------------------------
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.95
config.window_decorations = "INTEGRATED_BUTTONS | TITLE | RESIZE" -- or "RESIZE" for minimal

-- ---------------------------------------------------------------------------
-- Window / tabs / cursor
-- ---------------------------------------------------------------------------
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_style = {
  active_tab_foreground = "#cdd6f4",
  active_tab_background = "#45475a",
  inactive_tab_foreground = "#a6adc8",
  inactive_tab_background = "#1e1e2e",
}
config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBlock"

-- ---------------------------------------------------------------------------
-- Practical bits
-- ---------------------------------------------------------------------------
config.scrollback_lines = 10000
config.audible_bell = "Disabled" -- no beep

-- Clipboard via OSC-52 so nvim copy/paste works with the OS.
config.enable_osc52 = true

-- ---------------------------------------------------------------------------
-- Launch: default shell
-- ---------------------------------------------------------------------------
-- WSL users land inside their Linux distro shell automatically. On macOS you
-- can pin zsh; on plain Windows, PowerShell.
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { "powershell.exe" }
end

return config

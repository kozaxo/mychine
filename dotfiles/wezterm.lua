local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font("Fira Code", { weight = "Regular" })
config.font_size = 12.0

config.color_scheme = 'Everforest Dark Medium (Gogh)'

config.window_background_opacity = 0.65
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.keys = {
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'Enter',
    mods = 'SHIFT|ALT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = "h",
    mods = "ALT|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Left"),
  },
  {
    key = "l",
    mods = "ALT|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Right"),
  },
  {
    key = "k",
    mods = "ALT|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Up"),
  },
  {
    key = "j",
    mods = "ALT|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Down"),
  },
  {
    key = "h",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = "l",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivateTabRelative(1),
  },
}

return config

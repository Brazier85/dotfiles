-- Pull in the wezterm API
local wezterm = require("wezterm")
local hostname = wezterm.hostname()
-- This will hold the configuration.
local config = wezterm.config_builder()
local act = wezterm.action

-- Settings based on the PC
local font_size = 11.0
if string.find(hostname, "deagm") or string.find(hostname, "mate") then
	font_size = 12.0
end

-- Term size changes
config.initial_rows = 24
config.initial_cols = 100

-- Font changes
config.font_size = font_size
config.font = wezterm.font("MesloLGS NF")

-- Changing the color scheme:
config.color_scheme = "Obsidian"

-- Keybindings
config.keys = {
	{ key = "LeftArrow", mods = "CTRL|SUPER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|SUPER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|SUPER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|SUPER", action = act.ActivatePaneDirection("Down") },
}

-- Return the configuration to wezterm
return config
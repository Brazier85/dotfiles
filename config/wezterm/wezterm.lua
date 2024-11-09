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
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- Split Panes --
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Zoom Pane --
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	-- Move between Panes --
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	-- Spawn new Tab --
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	-- Show Launcher --
	{ key = "l", mods = "ALT", action = act.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }) },
	-- Change Tab name --
	{
		key = "E",
		mods = "CTRL|SHIFT",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

-- Map F-Keys to Tabs --
for i = 1, 8 do
	-- F1 through F8 to activate that tab
	table.insert(config.keys, {
		key = "F" .. tostring(i),
		action = act.ActivateTab(i - 1),
	})
end

config.launch_menu = {
	{
		label = "Top",
		args = { "top" },
	},
	{
		label = "Btop",
		args = { "btop" },
	},
}

-- Return the configuration to wezterm
return config

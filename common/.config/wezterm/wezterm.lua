local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Theme
config.color_scheme = "Eldritch"

-- Font
config.font = wezterm.font("JetBrains Mono")
config.font_size = 20.0

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 1000

-- Scrollback
config.scrollback_lines = 10000

-- Bell
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "Linear",
	fade_in_duration_ms = 0,
	fade_out_function = "Linear",
	fade_out_duration_ms = 0,
}

-- Window/appearance
config.window_background_opacity = 0.95
config.macos_window_background_blur = 15
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.window_decorations = "RESIZE"

-- Tab appearance
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 48

-- Keep rendering responsive, similar to low repaint/input delay intent
config.max_fps = 145
config.animation_fps = 145

-- URL behavior
config.underline_thickness = "2pt"
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Leader key for tmux-like mappings
config.leader = { key = "t", mods = "CTRL", timeout_milliseconds = 1200 }

-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	if name then
		if name == "resize_pane" then
			name = "RESIZE"
		end
	end
	window:set_right_status(name or "")
end)

config.keys = {
	-- Copy/Paste
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Pane split/close (ctrl+t prefix)
	{ key = "b", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			local tab = pane:tab()
			if not tab then
				return
			end
			local current_pane_id = pane:pane_id()
			for _, pane_info in ipairs(tab:panes_with_info()) do
				if pane_info.pane:pane_id() ~= current_pane_id then
					window:perform_action(act.CloseCurrentPane({ confirm = false }), pane_info.pane)
				end
			end
		end),
	},

	-- Pane navigation (vim style)
	{ key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },

	-- Resize mode
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- Layout-ish toggle
	{ key = "f", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },

	-- Tabs (ctrl+t prefix)
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = ",", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ".", mods = "LEADER", action = act.MoveTabRelative(1) },

	-- Font management
	{ key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },

	-- Misc
	{ key = "F11", action = act.ToggleFullScreen },
	{ key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "e", mods = "CTRL|SHIFT", action = act.QuickSelect },
}

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
}

return config

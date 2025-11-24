local wezterm = require("wezterm")
local action = wezterm.action
local config = wezterm.config_builder()

config.font_size = 16
config.font = wezterm.font("JetBrainsMono NerdFont", { weight = "Regular" })

config.default_cursor_style = "SteadyBlock"

config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.check_for_updates = true
config.detect_password_input = true
config.window_padding = {
  bottom = 4,
  top = 4,
  left = 4,
  right = 2,
}
config.window_background_opacity = 0.95
config.macos_window_background_blur = 10
config.win32_system_backdrop = "Acrylic"
config.warn_about_missing_glyphs = false

config.leader = { key = "t", mods = "CTRL", timeout_milliseconds = 1000 }

config.bypass_mouse_reporting_modifiers = "CTRL"
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = wezterm.action.Nop,
  },
}

-- Neovim navigation
-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true"
end
local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}
local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "META" or "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

-- Keybinds
config.keys = {
  -- Disables
  {
    key = "d",
    mods = "CTRL",
    action = action.DisableDefaultAssignment,
  },
  {
    key = "Enter",
    mods = "CTRL",
    action = action.DisableDefaultAssignment,
  },
  {
    key = "h",
    mods = "CTRL|SHIFT",
    action = action.DisableDefaultAssignment,
  },
  {
    key = "l",
    mods = "CTRL|SHIFT",
    action = action.DisableDefaultAssignment,
  },
  -- Rename Tab
  {
    key = "t",
    mods = "CTRL|SHIFT",
    action = action.PromptInputLine({
      description = "Rename tab",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  -- Vi mode
  {
    key = "c",
    mods = "CTRL|SHIFT",
    action = action.ActivateCopyMode,
  },
  -- Multiplexing
  {
    key = "b",
    mods = "LEADER",
    action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "v",
    mods = "LEADER",
    action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "x",
    mods = "LEADER",
    action = action.CloseCurrentPane({ confirm = false }),
  },
  split_nav("move", "h"),
  split_nav("move", "j"),
  split_nav("move", "k"),
  split_nav("move", "l"),
  -- TODO resize panes like kitty
  {
    key = "c",
    mods = "LEADER",
    action = action.SpawnTab("CurrentPaneDomain"),
  },
  -- TODO activate last tab
  -- {
  --   key="t",
  --   mods="LEADER",
  --   action= action.
  -- }
  {
    key = "1",
    mods = "LEADER",
    action = action.ActivateTab(0),
  },
  {
    key = "2",
    mods = "LEADER",
    action = action.ActivateTab(1),
  },
  {
    key = "3",
    mods = "LEADER",
    action = action.ActivateTab(2),
  },
  {
    key = "4",
    mods = "LEADER",
    action = action.ActivateTab(3),
  },
  {
    key = "5",
    mods = "LEADER",
    action = action.ActivateTab(4),
  },
  {
    key = "6",
    mods = "LEADER",
    action = action.ActivateTab(5),
  },
  {
    key = "7",
    mods = "LEADER",
    action = action.ActivateTab(6),
  },
  {
    key = "8",
    mods = "LEADER",
    action = action.ActivateTab(7),
  },
  {
    key = "9",
    mods = "LEADER",
    action = action.ActivateTab(8),
  },
  {
    key = "n",
    mods = "LEADER",
    action = action.ActivateTabRelative(1),
  },
  {
    key = "p",
    mods = "LEADER",
    action = action.ActivateTabRelative(-1),
  },
}

config.window_decorations = "RESIZE"
config.automatically_reload_config = true

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.tab_max_width = 120

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  local launch_powershell = {
    label = "Powershell 7",
    args = { "C:/Program Files/PowerShell/7/pwsh.exe" },
    domain = { DomainName = "local" },
  }
  config.launch_menu = {
    launch_powershell,
  }
  config.wsl_domains = {
    {
      name = "Arch",
      distribution = "Arch",
    },
  }

  config.window_decorations = "TITLE | RESIZE"
  config.default_domain = "Arch"
else -- Mac or Linux
  -- multiplexing
  config.unix_domains = {
    {
      name = "unix",
    },
  }
  config.inactive_pane_hsb = {
    brightness = 0.6,
  }
  config.default_gui_startup_args = { "connect", "unix" }
end

config.ssh_domains = {
  {
    name = "dockerbox",
    remote_address = "192.168.86.4",
    username = "neonvoid",
  },
  {
    name = "proxmox",
    remote_address = "192.168.86.2",
    username = "root",
  },
}

config.color_scheme = "Eldritch"

-- ####### PLUGINS #######
-- Quick Domains
local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")
domains.apply_to_config(config, {
  keys = {
    attach = {
      key = "d",
      mods = "LEADER",
      tbl = "",
    },
    hsplit = { key = "]", mods = "LEADER" },
    vsplit = { key = "[", mods = "LEADER" },
  },
})

-- Broadcast input
local cmd_sender = wezterm.plugin.require("https://github.com/aureolebigben/wezterm-cmd-sender")
cmd_sender.apply_to_config(config, {
  key = "mapped:i",
  mods = "LEADER",
  description = "Broadcast Input",
})

return config

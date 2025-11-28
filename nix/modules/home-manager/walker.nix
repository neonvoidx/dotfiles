{ config, pkgs, lib, ... }:

{
  # Walker is configured via xdg config file using TOML format
  xdg.configFile."walker/config.toml".text = lib.generators.toTOML {} {
    theme = "eldritch";
    force_keyboard_focus = true;
    close_when_open = true;
    click_to_close = true;
    selection_wrap = false;
    global_argument_delimiter = "#";
    exact_search_prefix = "'";
    disable_mouse = false;
    debug = false;
    page_jump_items = 10;
    hide_quick_activation = false;
    app_launch_prefix = "";
    resume_last_query = false;

    shell = {
      anchor_top = true;
      anchor_bottom = true;
      anchor_left = true;
      anchor_right = true;
    };

    placeholders = {
      default = { input = "Search"; list = "No Results"; };
    };

    keybinds = {
      close = [ "Escape" "ctrl q" ];
      next = [ "ctrl j" "Down" ];
      previous = [ "ctrl k" "Up" ];
      toggle_exact = [ "ctrl e" ];
      resume_last_query = [ "ctrl r" ];
      quick_activate = [ "F1" "F2" "F3" "F4" ];
      page_down = [ "ctrl d" ];
      page_up = [ "ctrl u" ];
    };

    providers = {
      default = [ "desktopapplications" ];
      empty = [ "desktopapplications" ];
      ignore_preview = [];
      max_results = 50;
      argument_delimiter = { runner = " "; };
      clipboard = { time_format = "%d.%m. - %H:%M"; };
    };
  };

  # Eldritch theme for walker
  xdg.configFile."walker/themes/eldritch.css".text = ''
    * {
      font-family: "JetBrains Mono", monospace;
    }
    #window {
      background-color: rgba(33, 35, 55, 0.95);
      border-radius: 12px;
      border: 2px solid #37f499;
    }
    #input {
      background-color: #323449;
      color: #ebfafa;
      border: none;
      border-radius: 8px;
      padding: 12px;
      font-size: 16px;
    }
    #input:focus {
      border: 1px solid #04d1f9;
    }
    #list {
      background-color: transparent;
    }
    #list row {
      padding: 8px 12px;
      border-radius: 6px;
      margin: 2px 0;
    }
    #list row:selected {
      background-color: #37f499;
      color: #212337;
    }
    #list row:hover {
      background-color: rgba(55, 244, 153, 0.2);
    }
    .item-title {
      color: #ebfafa;
      font-size: 14px;
    }
    .item-description {
      color: #7081d0;
      font-size: 12px;
    }
  '';
}

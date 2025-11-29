{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;

    # Font configuration
    font = {
      name = "JetBrains Mono";
      size = 16;
    };

    # Theme file (Eldritch theme)
    themeFile = "Eldritch";

    settings = {
      # Font rendering
      disable_ligatures = "never";
      cursor_trail = 3;

      # Linux-specific font config
      font_family = lib.mkIf pkgs.stdenv.isLinux "family='JetBrains Mono' postscript_name=JetBrainsMono-Regular";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = lib.mkIf pkgs.stdenv.isLinux "auto";

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 1;
      cursor = "#37f499";
      cursor_text_color = "#f8f8f2";

      # Scrollback
      scrollback_lines = 10000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";
      scrollback_pager_history_size = 4096;

      # Mouse
      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh";
      detect_urls = true;
      underline_hyperlinks = "always";
      paste_actions = "quote-urls-at-prompt";
      focus_follows_mouse = false;
      show_hyperlink_targets = true;

      # Performance
      repaint_delay = 1;
      input_delay = 1;
      sync_to_monitor = true;

      # Terminal bell
      enable_audio_bell = false;
      visual_bell_duration = 0;
      bell_on_tab = "󰂞 ";

      # Window layout
      enabled_layouts = "splits,stack";
      remember_window_size = true;
      draw_minimal_borders = true;
      window_border_width = "0.5pt";
      window_padding_width = 1;
      window_margin_width = 0;
      single_window_margin_width = 1;
      inactive_text_alpha = "1.0";
      single_window_padding_width = 0;
      background_opacity = if pkgs.stdenv.isLinux then "0.95" else "0.97";
      hide_window_decorations = "titlebar-only";
      confirm_os_window_close = 0;
      background_blur = 20;

      # Tab bar
      tab_bar_margin_width = 9;
      tab_bar_margin_height = "5 5";
      tab_bar_style = "separator";
      tab_bar_min_tabs = 1;
      tab_separator = "\"\"";
      tab_title_template = "\"{fmt.fg._323449}{fmt.bg.default}{fmt.fg._04d1f9}{fmt.bg.default}{index}{fmt.fg._04d1f9}{fmt.bg._323449} {title} {fmt.fg._323449}{fmt.bg.default} \"";
      active_tab_title_template = "\"{fmt.fg._37f499}{fmt.bg.default}{fmt.fg._212337}{fmt.bg._37f499}{fmt.fg._212337}{fmt.bg._37f499} {title} {fmt.fg._37f499}{fmt.bg.default} \"";
      active_tab_foreground = "#212337";
      active_tab_background = "#04d1f9";
      inactive_tab_foreground = "#37f499";
      inactive_tab_background = "#323449";

      # Border colors
      active_border_color = "#a48cf2";
      inactive_border_color = "#212337";

      # Marks
      mark1_foreground = "#212337";
      mark1_background = "#f9515d";

      # Advanced
      editor = ".";
      allow_remote_control = true;
      listen_on = "unix:/tmp/mykitty";
      update_check_interval = 6;
      clipboard_max_size = 512;
      allow_hyperlinks = true;
      shell_integration = "no-title";
      term = "xterm-kitty";

      # OS Specific - Wayland on Linux
      linux_display_server = "wayland";

      # Resize
      window_resize_step_lines = 5;

      # Undercurl
      undercurl_style = "thick-sparse";
    };

    # Keybindings
    keybindings = {
      # Disable defaults
      "cmd+enter" = "no_op";
      "ctrl+tab" = "no_op";

      # Copy/Paste
      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";

      # Scrolling
      "kitty_mod+up" = "scroll_page_up";
      "kitty_mod+down" = "scroll_page_down";
      "kitty_mod+j" = "scroll_to_prompt 1";
      "kitty_mod+k" = "scroll_to_prompt -1";
      "kitty_mod+o" = "show_last_command_output";

      # Tmux-like window management
      "ctrl+t>v" = "launch --location=vsplit --cwd=current";
      "ctrl+t>b" = "launch --location=hsplit --cwd=current";
      "ctrl+t>;" = "detach_window ask";
      "ctrl+t>x" = "close_window";

      # Move windows
      "ctrl+t>down" = "layout_action move_to_screen_edge bottom";
      "ctrl+t>up" = "layout_action move_to_screen_edge top";
      "ctrl+t>right" = "layout_action move_to_screen_edge right";
      "ctrl+t>left" = "layout_action move_to_screen_edge left";

      # Broadcast keys
      "ctrl+t>i" = "launch --allow-remote-control kitty +kitten broadcast --match-tab state:focused";

      # Resize
      "ctrl+t>r" = "kitten resize_window";

      # Swap windows
      "ctrl+t>s" = "swap_with_window";

      # Vim-kitty navigator
      "ctrl+j" = "kitten pass_keys.py bottom ctrl+j";
      "ctrl+k" = "kitten pass_keys.py top ctrl+k";
      "ctrl+h" = "kitten pass_keys.py left ctrl+h";
      "ctrl+l" = "kitten pass_keys.py right ctrl+l";

      # Layout
      "kitty_mod+f" = "toggle_layout stack";

      # Tab management
      "ctrl+t>1" = "goto_tab 1";
      "ctrl+t>2" = "goto_tab 2";
      "ctrl+t>3" = "goto_tab 3";
      "ctrl+t>4" = "goto_tab 4";
      "ctrl+t>5" = "goto_tab 5";
      "ctrl+t>6" = "goto_tab 6";
      "ctrl+t>7" = "goto_tab 7";
      "ctrl+t>8" = "goto_tab 8";
      "ctrl+t>9" = "goto_tab 9";
      "ctrl+t>n" = "next_tab";
      "ctrl+t>p" = "previous_tab";
      "ctrl+t>t" = "goto_tab -1";
      "ctrl+t>c" = "new_tab_with_cwd";
      "ctrl+t>w" = "close_tab";
      "ctrl+t>z" = "close_other_tabs_in_os_window";
      "ctrl+t>comma" = "move_tab_backward";
      "ctrl+t>period" = "move_tab_forward";

      # Scrollback with nvim
      "kitty_mod+h" = "kitty_scrollback_nvim";
      "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";

      # Font size
      "kitty_mod+plus" = "change_font_size all +1.0";
      "kitty_mod+minus" = "change_font_size all -1.0";

      # Misc
      "f11" = "toggle_fullscreen";
      "f12" = "kitten unicode_input --tab name --emoji-variation graphic";
      "kitty_mod+r" = "load_config_file";
      "kitty_mod+e" = "open_url_with_hints";

      # Marks
      "f1" = "toggle_marker text 1 TEST";
      "f2" = "toggle_marker text 2 ERROR";

      # Session management
      "f6" = "save_as_session --use-foreground-process --relocatable ~/.local/share/kitty/last-session.session";
      "f5" = "goto_session ~/.local/share/kitty/last-session.session";

      # Tab rename
      "ctrl+shift+t" = "kitten rename_tab.py";
    };

    # Symbol map for Nerd Fonts
    extraConfig = ''
      # Symbols Nerd Font complete symbol_map
      symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font Mono

      # Mouse mappings
      mouse_map right click grabbed,ungrabbed paste_from_clipboard
      mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output

      # Copy on select
      copy_on_select clipboard

      # Kitty-scrollback.nvim action alias
      action_alias kitty_scrollback_nvim kitten ~/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py
    '';
  };
}

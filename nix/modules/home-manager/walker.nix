{ config, pkgs, lib, ... }:

{
  # Walker launcher configuration
  xdg.configFile."walker/config.toml".text = ''
    theme = "eldritch"
    force_keyboard_focus = true
    close_when_open = true
    click_to_close = true
    selection_wrap = false
    global_argument_delimiter = "#"
    exact_search_prefix = "'"
    disable_mouse = false
    debug = false
    page_jump_items = 10
    hide_quick_activation = false
    app_launch_prefix = ""
    resume_last_query = false

    [shell]
    anchor_top = true
    anchor_bottom = true
    anchor_left = true
    anchor_right = true

    [placeholders]
    "default" = { input = "Search", list = "No Results" }

    [keybinds]
    close = ["Escape", "ctrl q"]
    next = ["ctrl j", "Down"]
    previous = ["ctrl k", "Up"]
    toggle_exact = ["ctrl e"]
    resume_last_query = ["ctrl r"]
    quick_activate = ["F1", "F2", "F3", "F4"]
    page_down = ["ctrl d"]
    page_up = ["ctrl u"]

    [providers]
    default = ["desktopapplications"]
    empty = ["desktopapplications"]
    ignore_preview = []
    max_results = 50

    [providers.argument_delimiter]
    runner = " "

    [[providers.prefixes]]
    prefix = ";"
    provider = "providerlist"

    [[providers.prefixes]]
    prefix = ">"
    provider = "runner"

    [[providers.prefixes]]
    prefix = "/"
    provider = "files"

    [[providers.prefixes]]
    prefix = "."
    provider = "symbols"

    [[providers.prefixes]]
    prefix = "!"
    provider = "todo"

    [[providers.prefixes]]
    prefix = "%"
    provider = "bookmarks"

    [[providers.prefixes]]
    prefix = "="
    provider = "calc"

    [[providers.prefixes]]
    prefix = "@"
    provider = "websearch"

    [[providers.prefixes]]
    prefix = ":"
    provider = "clipboard"

    [[providers.prefixes]]
    prefix = "$"
    provider = "windows"

    [providers.clipboard]
    time_format = "%d.%m. - %H:%M"

    [providers.actions]
    fallback = [
      { action = "menus:open", label = "open", after = "Nothing" },
      { action = "menus:default", label = "run", after = "Close" },
      { action = "menus:parent", label = "back", bind = "Escape", after = "Nothing" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "AsyncReload" },
    ]

    dmenu = [{ action = "select", default = true, bind = "Return" }]

    providerlist = [
      { action = "activate", default = true, bind = "Return", after = "ClearReload" },
    ]

    desktopapplications = [
      { action = "start", default = true, bind = "Return" },
      { action = "start:keep", label = "open+next", bind = "shift Return", after = "KeepOpen" },
      { action = "new_instance", label = "new instance", bind = "ctrl Return" },
      { action = "pin", bind = "ctrl p", after = "AsyncReload" },
      { action = "unpin", bind = "ctrl p", after = "AsyncReload" },
    ]

    files = [
      { action = "open", default = true, bind = "Return" },
      { action = "opendir", label = "open dir", bind = "ctrl Return" },
      { action = "copypath", label = "copy path", bind = "ctrl shift c" },
      { action = "copyfile", label = "copy file", bind = "ctrl c" },
    ]

    calc = [
      { action = "copy", default = true, bind = "Return" },
      { action = "delete", bind = "ctrl d", after = "AsyncReload" },
      { action = "save", bind = "ctrl s", after = "AsyncClearReload" },
    ]

    websearch = [{ action = "search", default = true, bind = "Return" }]

    runner = [
      { action = "run", default = true, bind = "Return" },
      { action = "runterminal", label = "run in terminal", bind = "shift Return" },
    ]

    clipboard = [
      { action = "copy", default = true, bind = "Return" },
      { action = "remove", bind = "ctrl d", after = "AsyncClearReload" },
      { action = "remove_all", label = "clear", bind = "ctrl shift d", after = "AsyncClearReload" },
    ]
  '';

  # Eldritch theme for Walker
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

    .item-icon {
      margin-right: 8px;
    }

    #quickfix {
      background-color: #323449;
      color: #04d1f9;
      border-radius: 4px;
      padding: 4px 8px;
      font-size: 12px;
    }
  '';
}

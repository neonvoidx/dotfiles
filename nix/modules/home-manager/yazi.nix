{ config, pkgs, lib, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = {
      manager = {
        ratio = [ 1 4 3 ];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        linemode = "permissions";
        show_hidden = true;
        show_symlink = true;
        mouse_events = [ "scroll" ];
      };

      preview = {
        wrap = "yes";
        tab_size = 2;
      };

      opener = {
        play = [
          { run = ''mpv "$@"''; orphan = true; for = "unix"; }
        ];
        edit = [
          { run = ''$EDITOR "$@"''; block = true; for = "unix"; }
        ];
        open = [
          { run = ''xdg-open "$@"''; desc = "Open"; }
        ];
      };

      tasks = {
        image_bound = [ 20000 20000 ];
        image_alloc = 1073741824;  # 1024MB
      };

      input = {
        cursor_blink = true;
      };
    };

    keymap = {
      manager = {
        prepend_keymap = [
          { on = [ "<C-q>" ]; run = "quit"; }
          { on = [ "u" ]; run = "undo"; }
          { on = [ "c" "a" "a" ]; run = "plugin compress"; desc = "Archive selected files"; }
          { on = [ "c" "a" "p" ]; run = "plugin compress -p"; desc = "Archive selected files (password)"; }
          { on = [ "c" "a" "h" ]; run = "plugin compress -ph"; desc = "Archive selected files (password+header)"; }
          { on = [ "c" "a" "l" ]; run = "plugin compress -l"; desc = "Archive selected files (compression level)"; }
          { on = [ "c" "a" "u" ]; run = "plugin compress -phl"; desc = "Archive selected files (password+header+level)"; }
          { on = [ "R" "b" ]; run = "plugin recycle-bin"; desc = "Open Recycle Bin menu"; }
          { on = [ "r" ]; run = "escape --visual | plugin thunar-bulk-rename"; desc = "Rename selected file(s) (via thunar)"; }
          { on = [ "g" "i" ]; run = "plugin lazygit"; desc = "run lazygit"; }
        ];
      };
    };

    theme = {
      manager = {
        cwd = { fg = "#04d1f9"; };
        hovered = { fg = "#212337"; bg = "#37f499"; };
        preview_hovered = { underline = true; };
        find_keyword = { fg = "#f1fc79"; italic = true; };
        find_position = { fg = "#f265b5"; bg = "reset"; italic = true; };
        marker_selected = { fg = "#37f499"; bg = "#37f499"; };
        marker_copied = { fg = "#f1fc79"; bg = "#f1fc79"; };
        marker_cut = { fg = "#f16c75"; bg = "#f16c75"; };
        tab_active = { fg = "#212337"; bg = "#37f499"; };
        tab_inactive = { fg = "#ebfafa"; bg = "#323449"; };
        tab_width = 1;
        border_symbol = "│";
        border_style = { fg = "#7081d0"; };
      };

      status = {
        separator_open = "";
        separator_close = "";
        separator_style = { fg = "#323449"; bg = "#323449"; };
        mode_normal = { fg = "#212337"; bg = "#37f499"; bold = true; };
        mode_select = { fg = "#212337"; bg = "#04d1f9"; bold = true; };
        mode_unset = { fg = "#212337"; bg = "#f16c75"; bold = true; };
        progress_label = { fg = "#ebfafa"; bold = true; };
        progress_normal = { fg = "#04d1f9"; bg = "#323449"; };
        progress_error = { fg = "#f16c75"; bg = "#323449"; };
        permissions_t = { fg = "#37f499"; };
        permissions_r = { fg = "#f1fc79"; };
        permissions_w = { fg = "#f16c75"; };
        permissions_x = { fg = "#04d1f9"; };
        permissions_s = { fg = "#7081d0"; };
      };

      input = {
        border = { fg = "#04d1f9"; };
        title = { };
        value = { };
        selected = { reversed = true; };
      };

      select = {
        border = { fg = "#04d1f9"; };
        active = { fg = "#f265b5"; };
        inactive = { };
      };

      tasks = {
        border = { fg = "#04d1f9"; };
        title = { };
        hovered = { underline = true; };
      };

      which = {
        mask = { bg = "#323449"; };
        cand = { fg = "#04d1f9"; };
        rest = { fg = "#7081d0"; };
        desc = { fg = "#f265b5"; };
        separator = "  ";
        separator_style = { fg = "#323449"; };
      };

      help = {
        on = { fg = "#f265b5"; };
        exec = { fg = "#04d1f9"; };
        desc = { fg = "#7081d0"; };
        hovered = { bg = "#323449"; bold = true; };
        footer = { fg = "#323449"; bg = "#ebfafa"; };
      };

      filetype = {
        rules = [
          { mime = "image/*"; fg = "#04d1f9"; }
          { mime = "video/*"; fg = "#f1fc79"; }
          { mime = "audio/*"; fg = "#f7c67f"; }
          { mime = "application/zip"; fg = "#f265b5"; }
          { mime = "application/gzip"; fg = "#f265b5"; }
          { mime = "application/x-tar"; fg = "#f265b5"; }
          { mime = "application/x-bzip"; fg = "#f265b5"; }
          { mime = "application/x-bzip2"; fg = "#f265b5"; }
          { mime = "application/x-7z-compressed"; fg = "#f265b5"; }
          { mime = "application/x-rar"; fg = "#f265b5"; }
          { name = "*"; fg = "#ebfafa"; }
          { name = "*/"; fg = "#04d1f9"; }
        ];
      };
    };
  };
}

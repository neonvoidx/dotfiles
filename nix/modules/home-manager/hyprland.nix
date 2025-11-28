{ config, pkgs, lib, inputs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      # Monitor configuration - adjust for your setup
      monitor = [
        ",preferred,auto,1"
      ];

      # Eldritch color definitions
      "$eldritch-bg" = "212337";
      "$eldritch-current-line" = "323449";
      "$eldritch-foreground" = "ebfafa";
      "$eldritch-comment" = "7081d0";
      "$eldritch-cyan" = "04d1f9";
      "$eldritch-green" = "37f499";
      "$eldritch-orange" = "f7c67f";
      "$eldritch-pink" = "f265b5";
      "$eldritch-purple" = "a48cf2";
      "$eldritch-red" = "f16c75";
      "$eldritch-yellow" = "f1fc79";

      "$mod" = "SUPER";

      # Startup applications
      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
        "systemctl --user start hyprpolkitagent"
        "udiskie"
        "wl-clip-persist --clipboard regular --reconnect-tries 0"
        "wl-paste --watch cliphist store"
        "nm-applet"
      ];

      # Input configuration
      input = {
        follow_mouse = 1;
        sensitivity = 0;
        scroll_factor = 1.0;
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 8;
        border_size = 3;
        "col.active_border" = "rgb($eldritch-green) rgb($eldritch-cyan) 90deg";
        "col.inactive_border" = "rgb($eldritch-purple)";
        "col.nogroup_border" = "rgb($eldritch-purple)";
        "col.nogroup_border_active" = "rgba(36F498FF)";
        resize_on_border = true;
        layout = "master";
        extend_border_grab_area = 3;
        hover_icon_on_border = false;
      };

      # Decoration
      decoration = {
        rounding = 8;
        dim_inactive = true;
        dim_strength = 0.05;
        
        blur = {
          enabled = true;
          size = 8;
          passes = 1;
          new_optimizations = true;
          ignore_opacity = true;
          xray = true;
        };

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          ignore_window = true;
          color = "rgb($eldritch-bg)";
        };
      };

      # Animations
      animations = {
        enabled = true;

        bezier = [
          "easeOutCubic,0.65, 0, 0.35, 0.8"
          "easeInOut,0.42,0,0.58,0.8"
          "overshoot, 0.05, 0.9, 0.1, 0.8"
        ];

        animation = [
          "windows, 1, 4, default, popin"
          "layers, 0"
          "workspaces,1,3,default,slide"
        ];
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
        default_split_ratio = 1;
      };

      # Master layout
      master = {
        new_status = "slave";
        new_on_top = false;
        allow_small_split = false;
        mfact = 0.58;
      };

      # Gestures
      gesture = {
        gesture = "3, horizontal, workspace";
      };

      # Misc
      misc = {
        disable_hyprland_logo = false;
        animate_manual_resizes = true;
        focus_on_activate = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
      };

      # XWayland
      xwayland = {
        force_zero_scaling = true;
      };

      # Debug
      debug = {
        disable_logs = true;
      };

      # Cursor
      cursor = {
        sync_gsettings_theme = true;
      };

      # Key bindings
      bind = [
        # App launchers
        "$mod, Return, exec, kitty"
        "$mod, q, killactive,"
        "$mod, b, exec, firefox-developer-edition"
        "$mod, Space, exec, rofi -show drun"
        "$mod, v, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, c, exec, hyprpicker -a -f hex"
        
        # Window management
        "$mod SHIFT, Space, togglefloating"
        "$mod SHIFT, Space, centerwindow"
        "$mod, f, fullscreen, 1"
        "$mod SHIFT, f, fullscreen, 0"
        "$mod, e, exec, thunar"
        "$mod, c, centerwindow"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp -d)\" - | wl-copy"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        
        # Focus movement
        "$mod, h, movefocus, l"
        "$mod, left, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, right, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, up, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod, down, movefocus, d"
        
        # Window movement
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, j, movewindow, d"
        "$mod SHIFT, down, movewindow, d"
        
        # Workspace switching
        "ALT, tab, workspace, previous"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, d, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, s, workspace, 10"
        "$mod, g, workspace, 11"
        
        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, d, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, s, movetoworkspace, 10"
        "$mod SHIFT, g, movetoworkspace, 11"
        
        # Focus workspace on current monitor
        "$mod CTRL SHIFT, 1, focusworkspaceoncurrentmonitor, 1"
        "$mod CTRL SHIFT, 2, focusworkspaceoncurrentmonitor, 2"
        "$mod CTRL SHIFT, 3, focusworkspaceoncurrentmonitor, 3"
        
        # Scroll through workspaces
        "$mod, mouse_down, workspace, m+1"
        "$mod, mouse_up, workspace, m-1"
      ];

      # Resize keybinds
      binde = [
        "$mod, equal, resizeactive, 10 10%"
        "$mod, minus, resizeactive, -10 -10%"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media keys
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "Ctrl, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "Ctrl, XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ -l 1"
        "Ctrl, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];
    };

    # Extra config for resize submap
    extraConfig = ''
      # Resize submap
      bind=$mod SHIFT,R,submap,resize
      submap=resize
      binde=,right,resizeactive,20 0
      binde=,left,resizeactive,-20 0
      binde=,up,resizeactive,0 -20
      binde=,down,resizeactive,0 20
      binde=,l,resizeactive,20 0
      binde=,h,resizeactive,-20 0
      binde=,k,resizeactive,0 -20
      binde=,j,resizeactive,0 20
      bind=,escape,submap,reset
      submap=reset
    '';
  };
}

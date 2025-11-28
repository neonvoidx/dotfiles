{ config, pkgs, lib, ... }:

{
  programs.btop = {
    enable = true;
    
    settings = {
      # Theme - referencing eldritch theme
      color_theme = "eldritch";
      
      # Background
      theme_background = false;
      
      # Truecolor
      truecolor = true;
      
      # Force TTY mode
      force_tty = false;
      
      # Presets
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      
      # Vim keys
      vim_keys = true;
      
      # Rounded corners
      rounded_corners = true;
      
      # Graph symbols
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_gpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      
      # Shown boxes
      shown_boxes = "cpu mem proc";
      
      # Update time
      update_ms = 1500;
      
      # Process settings
      proc_sorting = "threads";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;
      proc_aggregate = false;
      
      # CPU settings
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      show_gpu_info = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = true;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      temp_scale = "celsius";
      show_cpu_freq = true;
      
      # Clock
      clock_format = "%X";
      
      # Background update
      background_update = true;
      
      # Memory settings
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      
      # Network settings
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = false;
      base_10_bitrate = "Auto";
      
      # Battery
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;
      
      # Logging
      log_level = "WARNING";
      
      # GPU
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
    };
  };

  # Create eldritch theme file
  xdg.configFile."btop/themes/eldritch.theme".text = ''
    # Eldritch theme for btop
    # Main background
    theme[main_bg]="#212337"

    # Main text color
    theme[main_fg]="#ebfafa"

    # Title color for boxes
    theme[title]="#ebfafa"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#04d1f9"

    # Background color of selected items
    theme[selected_bg]="#323449"

    # Foreground color of selected items
    theme[selected_fg]="#ebfafa"

    # Color of inactive/disabled text
    theme[inactive_fg]="#7081d0"

    # Color of text appearing on top of graphs
    theme[graph_text]="#f7c67f"

    # Misc colors for processes box including mini cpu graphs
    theme[proc_misc]="#04d1f9"

    # CPU, Memory, Network, Proc box outline color
    theme[cpu_box]="#37f499"
    theme[mem_box]="#a48cf2"
    theme[net_box]="#f265b5"
    theme[proc_box]="#04d1f9"

    # Box divider line and target icon
    theme[div_line]="#323449"

    # Temperature graph color
    theme[temp_start]="#37f499"
    theme[temp_mid]="#f7c67f"
    theme[temp_end]="#f16c75"

    # CPU graph colors
    theme[cpu_start]="#37f499"
    theme[cpu_mid]="#04d1f9"
    theme[cpu_end]="#a48cf2"

    # Mem/Disk free meter
    theme[free_start]="#323449"
    theme[free_mid]="#7081d0"
    theme[free_end]="#a48cf2"

    # Mem/Disk cached meter
    theme[cached_start]="#04d1f9"
    theme[cached_mid]="#37f499"
    theme[cached_end]="#f1fc79"

    # Mem/Disk available meter
    theme[available_start]="#f7c67f"
    theme[available_mid]="#f265b5"
    theme[available_end]="#f16c75"

    # Mem/Disk used meter
    theme[used_start]="#37f499"
    theme[used_mid]="#04d1f9"
    theme[used_end]="#a48cf2"

    # Download graph colors
    theme[download_start]="#04d1f9"
    theme[download_mid]="#37f499"
    theme[download_end]="#f1fc79"

    # Upload graph colors
    theme[upload_start]="#f265b5"
    theme[upload_mid]="#a48cf2"
    theme[upload_end]="#f16c75"

    # Process box color gradient for threads, mem and cpu usage
    theme[process_start]="#04d1f9"
    theme[process_mid]="#37f499"
    theme[process_end]="#a48cf2"
  '';
}

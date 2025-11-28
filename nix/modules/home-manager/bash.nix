{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    
    bashrcExtra = ''
      # Path to the bash it configuration
      BASH_IT="/home/neonvoid/.bash_it"
      
      export BASH_IT_THEME='purity'
      THEME_CHECK_SUDO='true'
      SCM_CHECK=true
      BASH_IT_COMMAND_DURATION=true
      COMMAND_DURATION_MIN_SECONDS=1
      SHORT_TERM_LINE=true
      BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1
      
      if [ -f "''${BASH_IT}/bash_it.sh" ]; then
        source "''${BASH_IT}/bash_it.sh"
      fi
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };
}

{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    jetbrains-mono
    (nerd-fonts.jetbrains-mono)
    roboto
  ];
}

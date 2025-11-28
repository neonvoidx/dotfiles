{ config, pkgs, lib, ... }:

{
  programs.lsd = {
    enable = true;
    settings = {
      classic = false;
      blocks = [ "permission" "user" "group" "size" "date" "name" "git" ];
      color = {
        when = "always";
        theme = "custom";
      };
      date = "+%y%b%d %H:%M:%S";
      dereference = false;
      icons = {
        when = "always";
        theme = "fancy";
        separator = " ";
      };
      indicators = false;
      layout = "grid";
      recursion = {
        enabled = false;
      };
      size = "default";
      permission = "rwx";
      sorting = {
        column = "name";
        reverse = false;
        dir-grouping = "first";
      };
      no-symlink = false;
      total-size = false;
      hyperlink = "never";
      symlink-arrow = "➠";
      header = false;
      literal = false;
      truncate-owner = {
        marker = "";
      };
    };
    colors = {
      user = "#37f499";
      group = "#04d1f9";
      permission = {
        read = "#37f499";
        write = "#f7c67f";
        exec = "#f16c75";
        exec-sticky = "#f265b5";
        no-access = "#7081d0";
        octal = "#a48cf2";
        acl = "#04d1f9";
        context = "#f1fc79";
      };
      date = {
        hour-old = "#37f499";
        day-old = "#04d1f9";
        older = "#7081d0";
      };
      size = {
        none = "#7081d0";
        small = "#37f499";
        medium = "#f7c67f";
        large = "#f16c75";
      };
      inode = {
        valid = "#a48cf2";
        invalid = "#f16c75";
      };
      links = {
        valid = "#a48cf2";
        invalid = "#f16c75";
      };
      tree-edge = "#323449";
      git-status = {
        default = "#7081d0";
        unmodified = "#ebfafa";
        ignored = "#7081d0";
        new-in-index = "#37f499";
        new-in-workdir = "#37f499";
        typechange = "#f7c67f";
        deleted = "#f16c75";
        renamed = "#04d1f9";
        modified = "#f7c67f";
        conflicted = "#f16c75";
      };
    };
  };
}

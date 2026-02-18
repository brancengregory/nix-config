{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.home.desktop.hyprland;
in {
  options.home.desktop.hyprland = {
    enable = mkEnableOption "Hyprland window manager configuration";

    enableNvidiaPatches = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Nvidia-specific patches for Hyprland";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional Hyprland configuration";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprland
      waybar
      rofi
    ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      extraConfig = cfg.extraConfig;
    };
  };
}

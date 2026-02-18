{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.desktop.sddm;
in {
  options.desktop.sddm = {
    enable = mkEnableOption "SDDM display manager";

    theme = mkOption {
      type = types.str;
      default = "";
      description = "SDDM theme to use (e.g., 'sugar-dark' or 'maldives'). Leave empty for default.";
      example = "sugar-dark";
    };
  };

  config = mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Crucial for Wayland compositors like Hyprland
      theme = lib.mkIf (cfg.theme != "") cfg.theme;
    };
  };
}

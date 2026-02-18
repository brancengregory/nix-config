{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.modules.hardware.bluetooth;
in {
  options.modules.hardware.bluetooth = {
    enable = mkEnableOption "Bluetooth subsystem";

    powerOnBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Power on Bluetooth adapter at boot (default false for battery/security)";
    };

    guiManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable graphical Bluetooth manager (blueman)";
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };

    services.blueman.enable = cfg.guiManager;
  };
}

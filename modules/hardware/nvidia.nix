{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA GPU drivers and configuration";

    open = mkOption {
      type = types.bool;
      default = false;
      description = "Use open-source NVIDIA kernel modules (Turing+ GPUs only)";
    };

    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (saves VRAM to /tmp/ on sleep). Experimental - can cause sleep/suspend issues.";
      };

      finegrained = mkOption {
        type = types.bool;
        default = false;
        description = "Enable fine-grained power management (turns off GPU when not in use). Experimental, requires modern GPU (Turing+).";
      };
    };

    nvidiaSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Enable nvidia-settings GUI tool";
    };
  };

  config = mkIf cfg.enable {
    # Enable OpenGL/Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Load NVIDIA driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      inherit (cfg) open;
      nvidiaSettings = cfg.nvidiaSettings;
      powerManagement = cfg.powerManagement;
    };
  };
}

{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.virtualization.podman;
in {
  options.virtualization.podman = {
    enable = mkEnableOption "Podman container engine (Docker replacement)";

    dockerCompat = mkOption {
      type = types.bool;
      default = true;
      description = "Create 'docker' command alias for Podman (conflicts with Docker if both enabled)";
    };

    dnsEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNS for default Podman network (allows container-to-container communication)";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [ distrobox podman-compose podman-tui ];
      description = "Additional Podman-related packages to install";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = cfg.dockerCompat;
        defaultNetwork.settings.dns_enabled = cfg.dnsEnabled;
      };
    };

    environment.systemPackages = cfg.extraPackages;
  };
}

# modules/services/opencode.nix
# OpenCode server - remote coding agent backend
# Note: This is NixOS-only. On macOS, use Homebrew instead:
#   homebrew.brews = [ "anomalyco/tap/opencode" ];
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.opencode-server;
  # Only define package on Linux (NixOS)
  opencodePackage =
    if pkgs.system == "x86_64-linux" || pkgs.system == "aarch64-linux"
    then inputs.opencode-flake.packages.${pkgs.system}.default
    else null;
in {
  assertions = [
    {
      assertion = !(cfg.enable && opencodePackage == null);
      message = "OpenCode server is only supported on NixOS Linux. On macOS, install via Homebrew.";
    }
  ];

  options.services.opencode-server = {
    enable = mkEnableOption "OpenCode server (remote coding agent backend)";

    port = mkOption {
      type = types.port;
      default = 8081;
      description = "Port for OpenCode server";
    };

    workingDir = mkOption {
      type = types.str;
      default = "/home/brancengregory/code";
      description = "Working directory for OpenCode server";
    };

    user = mkOption {
      type = types.str;
      default = "brancengregory";
      description = "User to run OpenCode server as";
    };
  };

  config = mkIf cfg.enable {
    # Ensure opencode is available system-wide
    environment.systemPackages = [opencodePackage];

    # Create working directory
    systemd.tmpfiles.rules = [
      "d ${cfg.workingDir} 0755 ${cfg.user} users -"
    ];

    # OpenCode server systemd service
    systemd.services.opencode-server = {
      description = "OpenCode server - remote coding agent backend";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        WorkingDirectory = cfg.workingDir;
        ExecStart = "${opencodePackage}/bin/opencode web --port ${toString cfg.port} --hostname 0.0.0.0";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [cfg.workingDir "/home/${cfg.user}/.local/share/opencode" "/home/${cfg.user}/.config/opencode"];
      };

      environment = {
        HOME = "/home/${cfg.user}";
        PATH = lib.mkForce (lib.makeBinPath [pkgs.git pkgs.openssh pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused pkgs.systemd]);
      };
    };

    # Firewall managed by host (VPN-only)
  };
}

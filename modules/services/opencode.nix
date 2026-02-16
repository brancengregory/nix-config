# modules/services/opencode.nix
# OpenCode server - remote coding agent backend
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.opencode-server;
in {
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
    environment.systemPackages = [ pkgs.opencode ];

    # Create working directory
    systemd.tmpfiles.rules = [
      "d ${cfg.workingDir} 0755 ${cfg.user} users -"
    ];

    # OpenCode server systemd service
    systemd.services.opencode-server = {
      description = "OpenCode server - remote coding agent backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        WorkingDirectory = cfg.workingDir;
        ExecStart = "${pkgs.opencode}/bin/opencode web --port ${toString cfg.port} --hostname 0.0.0.0";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ cfg.workingDir "/home/${cfg.user}/.local/share/opencode" "/home/${cfg.user}/.config/opencode" ];
      };

      environment = {
        HOME = "/home/${cfg.user}";
        PATH = lib.makeBinPath [ pkgs.git pkgs.openssh ];
      };
    };

    # Firewall managed by host (VPN-only)
  };
}

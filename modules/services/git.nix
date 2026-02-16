# modules/services/git.nix
# Git services: Forgejo (self-hosted Git forge)
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.git-server;
in {
  options.services.git-server = {
    enable = mkEnableOption "Git server (Forgejo)";

    forgejo = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Forgejo (Git forge)";
      };
      domain = mkOption {
        type = types.str;
        default = "git.local";
        description = "Forgejo domain";
      };
      httpPort = mkOption {
        type = types.port;
        default = 3080;
        description = "HTTP port for Forgejo";
      };
      sshPort = mkOption {
        type = types.port;
        default = 22;
        description = "SSH port for Forgejo (conflicts with system SSH on 77)";
      };
    };

    dataDir = mkOption {
      type = types.str;
      default = "/mnt/storage/critical/forgejo";
      description = "Forgejo data directory";
    };
  };

  config = mkIf cfg.enable {
    # Using container since Forgejo module is complex
    # Current setup uses port 3080 for HTTP and 22 for SSH
    virtualisation.oci-containers.containers.forgejo = mkIf cfg.forgejo.enable {
      image = "codeberg.org/forgejo/forgejo:10";
      autoStart = true;
      ports = [
        "${toString cfg.forgejo.httpPort}:3000" # HTTP
        "${toString cfg.forgejo.sshPort}:22" # SSH
      ];
      volumes = [
        "${cfg.dataDir}:/data"
      ];
      environment = {
        USER_UID = "1000";
        USER_GID = "1000";
        FORGEJO__server__ROOT_URL = "http://${cfg.forgejo.domain}:${toString cfg.forgejo.httpPort}/";
        FORGEJO__server__SSH_PORT = toString cfg.forgejo.sshPort;
        FORGEJO__server__SSH_DOMAIN = cfg.forgejo.domain;
        FORGEJO__server__START_SSH_SERVER = "true";
      };
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 1000 1000 -"
    ];

    # Note: Using port 22 for Forgejo SSH means system SSH must use a different port
    # Current setup has system SSH on port 77, which is preserved
    # Firewall managed by host (VPN-only)
  };
}

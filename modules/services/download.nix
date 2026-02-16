# modules/services/download.nix
# Download clients: qBittorrent (multiple instances), SABnzbd
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.download-stack;
in {
  options.services.download-stack = {
    enable = mkEnableOption "Download stack (qBittorrent, SABnzbd)";

    qbittorrent = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable qBittorrent";
      };
      instances = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              description = "Web UI port for this instance";
            };
            user = mkOption {
              type = types.str;
              description = "User to run qBittorrent as";
            };
            downloadDir = mkOption {
              type = types.str;
              description = "Download directory";
            };
          };
        });
        default = {};
        description = "qBittorrent instances configuration";
      };
    };

    sabnzbd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SABnzbd";
      };
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/storage/ephemeral/downloads";
      description = "Base download directory";
    };
  };

  config = mkIf cfg.enable {
    # qBittorrent instances (using containers for flexibility)
    virtualisation.oci-containers.containers = mkMerge [
      # Default qBittorrent instance for brancengregory
      (mkIf cfg.qbittorrent.enable {
        qbittorrent-brancengregory = {
          image = "linuxserver/qbittorrent:latest";
          autoStart = true;
          ports = ["8080:8080" "6881:6881" "6881:6881/udp"];
          volumes = [
            "/var/lib/qbittorrent/brancengregory:/config"
            "${cfg.downloadDir}:/downloads"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = config.time.timeZone;
            WEBUI_PORT = "8080";
          };
        };
      })

      # Additional qBittorrent instance (e.g., for qbt user)
      (mkIf cfg.qbittorrent.enable {
        qbittorrent-qbt = {
          image = "linuxserver/qbittorrent:latest";
          autoStart = true;
          ports = ["8081:8080" "6882:6881" "6882:6881/udp"];
          volumes = [
            "/var/lib/qbittorrent/qbt:/config"
            "${cfg.downloadDir}:/downloads"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = config.time.timeZone;
            WEBUI_PORT = "8080";
          };
        };
      })
    ];

    # SABnzbd (NZB downloader)
    services.sabnzbd = mkIf cfg.sabnzbd.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };
    # Add sabnzbd user to media group for shared access
    users.users.sabnzbd.extraGroups = ["media"];

    # Add brancengregory user to media group (for qBittorrent container access)
    users.users.brancengregory.extraGroups = ["media"];

    # Create directories with setgid bit (2775) for shared group access
    # Downloads directory owned by root:media, with setgid so new files inherit media group
    systemd.tmpfiles.rules = [
      "d /var/lib/qbittorrent 0755 root root -"
      "d /var/lib/qbittorrent/brancengregory 0755 1000 1000 -"
      "d /var/lib/qbittorrent/qbt 0755 1000 1000 -"
      "d ${cfg.downloadDir} 2775 root media -"
      "d ${cfg.downloadDir}/complete 2775 root media -"
      "d ${cfg.downloadDir}/incomplete 2775 root media -"
      "d ${cfg.downloadDir}/watch 2775 root media -"
      "d ${cfg.downloadDir}/nzb 2775 root media -"
    ];
  };
}

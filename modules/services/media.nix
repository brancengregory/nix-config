# modules/services/media.nix
# Media server stack: Jellyfin, Sonarr, Radarr, Lidarr, Readarr, Prowlarr
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.media;
in {
  options.services.media = {
    enable = mkEnableOption "Media server stack (Jellyfin, Sonarr, Radarr, Lidarr, Readarr, Prowlarr)";

    jellyfin = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyfin media server";
      };
    };

    sonarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sonarr (TV)";
      };
    };

    radarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Radarr (Movies)";
      };
    };

    lidarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Lidarr (Music)";
      };
    };

    readarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Readarr (Books)";
      };
    };

    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prowlarr (indexer manager)";
      };
    };

    jellyseerr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyseerr (request management)";
      };
    };

    ombi = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Ombi (alternative request management)";
      };
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib";
      description = "Base directory for service data";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/mnt/storage/standard/media";
      description = "Media storage directory";
    };
  };

  config = mkIf cfg.enable {
    # Jellyfin
    services.jellyfin = mkIf cfg.jellyfin.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Sonarr (TV)
    services.sonarr = mkIf cfg.sonarr.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Radarr (Movies)
    services.radarr = mkIf cfg.radarr.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Lidarr (Music)
    services.lidarr = mkIf cfg.lidarr.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Readarr (Books)
    services.readarr = mkIf cfg.readarr.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Prowlarr (Indexer manager)
    services.prowlarr = mkIf cfg.prowlarr.enable {
      enable = true;
      # Firewall managed by host (VPN-only)
    };

    # Jellyseerr (request management for Jellyfin)
    # Using container since no NixOS module exists
    virtualisation.oci-containers.containers.jellyseerr = mkIf cfg.jellyseerr.enable {
      image = "fallenbagel/jellyseerr:latest";
      autoStart = true;
      ports = ["5055:5055"];
      volumes = [
        "/var/lib/jellyseerr:/app/config"
      ];
      environment = {
        LOG_LEVEL = "info";
        TZ = config.time.timeZone;
      };
    };

    # Ombi (alternative request management)
    virtualisation.oci-containers.containers.ombi = mkIf cfg.ombi.enable {
      image = "linuxserver/ombi:latest";
      autoStart = true;
      ports = ["3579:3579"];
      volumes = [
        "/var/lib/ombi:/config"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = config.time.timeZone;
      };
    };

    # Create media directories
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir}/movies 0775 jellyfin jellyfin -"
      "d ${cfg.mediaDir}/tv 0775 jellyfin jellyfin -"
      "d ${cfg.mediaDir}/music 0775 jellyfin jellyfin -"
      "d ${cfg.mediaDir}/books 0775 jellyfin jellyfin -"
      "d /var/lib/jellyseerr 0755 root root -"
      "d /var/lib/ombi 0755 root root -"
    ];

    # Ensure jellyfin user can access media
    users.users.jellyfin.extraGroups = ["users"];
  };
}

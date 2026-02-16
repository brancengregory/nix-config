# modules/services/storage.nix
# Storage services: Minio, NFS, mergerfs, SnapRAID
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.storage;
in {
  options.services.storage = {
    enable = mkEnableOption "Storage stack (mergerfs, SnapRAID, NFS, Minio)";

    mergerfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable mergerfs pools";
      };
    };

    snapraid = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SnapRAID";
      };
    };

    nfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NFS server";
      };
      exports = mkOption {
        type = types.str;
        default = "";
        description = "NFS exports configuration";
      };
    };

    minio = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Minio S3-compatible storage";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/mnt/storage/standard/minio";
        description = "Minio data directory";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mergerfs.enable -> (config.fileSystems."/mnt/vault1" or {} != {});
        message = "Storage service requires /mnt/vault1 to be mounted. Please configure LUKS unlock and mount points for vault drives.";
      }
    ];
    # Install required packages
    environment.systemPackages = with pkgs; [
      mergerfs
      mergerfs-tools
      snapraid
      nfs-utils
      minio
    ];

    # MergerFS pools
    fileSystems = mkIf cfg.mergerfs.enable {
      # Critical pool - vault1 + vault2
      "/mnt/storage/critical" = {
        device = "/mnt/vault1/critical:/mnt/vault2/critical";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "allow_other"
          "category.create=epmfs" # Existing path, most free space
          "moveonenospc=true"
          "minfreespace=4G"
          "fsname=mergerfs-critical"
        ];
      };

      # Standard pool - vault1 + vault2
      "/mnt/storage/standard" = {
        device = "/mnt/vault1/standard:/mnt/vault2/standard";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "allow_other"
          "category.create=epmfs"
          "moveonenospc=true"
          "minfreespace=4G"
          "fsname=mergerfs-standard"
        ];
      };

      # Ephemeral pool - vault1 + vault2 (first found policy)
      "/mnt/storage/ephemeral" = {
        device = "/mnt/vault1/ephemeral:/mnt/vault2/ephemeral";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "allow_other"
          "category.create=ff" # First found
          "moveonenospc=true"
          "minfreespace=4G"
          "fsname=mergerfs-ephemeral"
        ];
      };
    };

    # SnapRAID configuration
    environment.etc."snapraid.conf".text = mkIf cfg.snapraid.enable ''
      ###################################
      # PARITY
      ###################################
      parity /mnt/vault3/parity/snapraid.parity

      ###################################
      # CONTENT FILES (metadata)
      ###################################
      content /var/snapraid/snapraid.content
      content /mnt/vault1/snapraid.content
      content /mnt/vault2/snapraid.content
      content /mnt/vault3/snapraid.content

      ###################################
      # DATA
      ###################################
      data d1 /mnt/vault1/critical
      data d2 /mnt/vault1/standard
      data d3 /mnt/vault2/critical
      data d4 /mnt/vault2/standard

      ###################################
      # EXCLUDE ephemeral
      ###################################
      exclude /mnt/*/ephemeral
    '';

    # SnapRAID systemd service
    systemd.services.snapraid-sync = mkIf cfg.snapraid.enable {
      description = "SnapRAID synchronization";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.snapraid}/bin/snapraid sync";
      };
    };

    systemd.timers.snapraid-sync = mkIf cfg.snapraid.enable {
      description = "Run SnapRAID sync weekly";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # NFS Server
    services.nfs.server = mkIf cfg.nfs.enable {
      enable = true;
      exports = cfg.nfs.exports;
    };

    # Minio
    services.minio = mkIf cfg.minio.enable {
      enable = true;
      listenAddress = ":9000";
      consoleAddress = ":9001";
      rootCredentialsFile = config.sops.secrets."minio/root_credentials".path;
    };

    # Ensure snapraid content directory exists
    systemd.tmpfiles.rules = mkIf cfg.snapraid.enable [
      "d /var/snapraid 0755 root root -"
    ];
  };
}

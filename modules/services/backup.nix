{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.backup;
in {
  options.services.backup = {
    enable = mkEnableOption "Restic backup service";

    repository = mkOption {
      type = types.str;
      description = "Restic repository URL (e.g., gs:bucket-name:path)";
      example = "gs:my-backup-bucket:/backups";
    };

    backupName = mkOption {
      type = types.str;
      default = "daily-home";
      description = "Name for this backup configuration";
    };

    paths = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Paths to backup (must be explicitly defined)";
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [
        ".cache"
        "Downloads"
        ".local/share/Trash"
        ".git"
        "node_modules"
      ];
      description = "Patterns to exclude from backup";
    };

    passwordFile = mkOption {
      type = types.str;
      description = "Path to restic repository password file";
    };

    environmentFile = mkOption {
      type = types.str;
      description = "Path to environment file with cloud credentials";
    };

    timerConfig = mkOption {
      type = types.attrs;
      default = {
        OnCalendar = "daily";
        Persistent = true;
      };
      description = "Systemd timer configuration";
    };

    pruneOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
      description = "Restic prune options for retention policy";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configuration to pass to the restic backup service";
    };
  };

  config = mkIf cfg.enable {
    services.restic.backups.${cfg.backupName} =
      {
        inherit (cfg) repository paths exclude timerConfig pruneOpts passwordFile environmentFile;
        initialize = true;
      }
      // cfg.extraConfig;

    environment.systemPackages = [pkgs.restic];
  };
}

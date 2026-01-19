{
  config,
  pkgs,
  ...
}: {
  # Restic Backup Configuration
  #
  # Note: This requires two files to be present on the system:
  # 1. /etc/nixos/secrets/restic-password (The backup repository password)
  # 2. /etc/nixos/secrets/restic-env (GCS credentials: GOOGLE_PROJECT_ID, GOOGLE_APPLICATION_CREDENTIALS)

  services.restic.backups = {
    daily-home = {
      initialize = true;

      # GCS Repository
      repository = "gs:powerhouse-backup:/";

      # Credentials (evaluation requires these to be set)
      passwordFile = config.sops.secrets."restic/password".path;
      environmentFile = config.sops.secrets."restic/env".path;

      paths = ["/home/brancengregory"];

      exclude = [
        "/home/brancengregory/.cache"
        "/home/brancengregory/Downloads"
        "/home/brancengregory/.local/share/Trash"
        ".git"
        "node_modules"
      ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };

  # Ensure restic is installed for manual operations
  environment.systemPackages = [pkgs.restic];
}

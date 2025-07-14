{ pkgs, ... }: {
  # GPG Agent configuration for SSH and GPG operations
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableScDaemon = true;

    pinentry.package = pkgs.pinentry-curses;

    # Agent settings
    defaultCacheTtl = 28800; # 8 hours
    defaultCacheTtlSsh = 28800; # 8 hours
    maxCacheTtl = 86400; # 24 hours
    maxCacheTtlSsh = 86400; # 24 hours

    # Extra configuration for tmux compatibility
    extraConfig = ''
      allow-preset-passphrase
      no-allow-external-cache
      enforce-passphrase-constraints
      min-passphrase-len 12
      min-passphrase-nonalpha 2

      # Tmux compatibility improvements
      # Allow loopback pinentry for better tmux integration
      allow-loopback-pinentry

      # Debug options (can be removed in production)
      # debug-level guru
      # log-file /tmp/gpg-agent.log
    '';
  };
}

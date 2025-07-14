{pkgs, ...}: {

  # --- Localization ---

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Shell ---

  # Enable system-wide integration for Zsh
  programs.zsh.enable = true;

  # --- Networking ---

  # Use networkd, disabling conflicting services like dhcpcd
  networking.useNetworkd = true;

  # Using systemd-networkd for networking
  systemd.network.enable = true;

  # Using systemd-resolved for DNS
  services.resolved.enable = true;

  # --- User Account ---

  users.users.brancengregory = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    initialHashedPassword = "password";
    # Password should be set during initial setup, not hardcoded
    # Use: sudo passwd brancengregory
  };
}

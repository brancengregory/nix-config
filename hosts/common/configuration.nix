{ pkgs, ... }:

{
  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  # Using systemd-networkd for networking
  systemd.network.enable = true;

  # Using systemd-resolved for DNS
  systemd.resolved.enable = true;

  users.users.brancengregory = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    initialPassword = "password";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

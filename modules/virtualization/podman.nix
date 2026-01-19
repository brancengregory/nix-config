{pkgs, ...}: {
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Useful tools for container management
  environment.systemPackages = with pkgs; [
    distrobox
    podman-compose
    podman-tui
  ];
}
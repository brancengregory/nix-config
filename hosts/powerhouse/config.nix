{pkgs, ...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ../../modules/desktop/sddm.nix
  ];

  networking.hostName = "powerhouse";

  home-manager.users.brancengregory = {
    imports = [
      ../../users/brancengregory/home.nix
      ../../modules/desktop/hyprland.nix
    ];
  };

  system.stateVersion = "25.05";
}

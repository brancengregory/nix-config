{pkgs, ...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
  ];

  networking.hostName = "powerhouse";

  system.stateVersion = "25.05";
}

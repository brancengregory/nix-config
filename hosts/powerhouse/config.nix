{pkgs, ...}: {
  imports = [
    ../../modules/common.nix # Universal settings
    ../../modules/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
  ];

  networking.hostName = "powerhouse";

  system.stateVersion = "25.05";
}

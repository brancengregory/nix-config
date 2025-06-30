{pkgs, ...}: {
  imports = [
    ../../modules/common.nix # Universal settings
    ../../modules/nixos.nix # Common NixOS settings
    # Might eventually have hardware-specific configs here too
  ];

  networking.hostName = "powerhouse";

  system.stateVersion = "25.05";
}

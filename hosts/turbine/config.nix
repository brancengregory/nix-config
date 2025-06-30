{pkgs, ...}: {
  imports = [
    ../../modules/common.nix # Universal settings
    ../../modules/darwin.nix # Common MacOS settings
  ];

  system.stateVersion = 5;
}

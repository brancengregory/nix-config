{pkgs, ...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
  ];

  system.stateVersion = 5;
}

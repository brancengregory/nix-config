{...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
    ../../modules/themes # Bundle: stylix and other themes
  ];

  # Enable stylix on macOS
  themes.stylix.enable = true;

  system.stateVersion = 5;
}

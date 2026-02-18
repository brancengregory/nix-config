{
  pkgs,
  inputs,
  isLinux,
  isDarwin,
  isDesktop,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
    ../../modules/themes/stylix.nix
  ];

  system.stateVersion = 5;
}

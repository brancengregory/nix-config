{pkgs, ...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
  ];

  home-manager.users.brancengregory = {
    imports = [
      ../../users/brancengregory/home.nix
    ];
  };

  system.stateVersion = 5;
}

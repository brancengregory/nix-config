{
  pkgs,
  inputs,
  isLinux,
  isDarwin,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
    ../../modules/themes/stylix.nix
  ];

  home-manager.extraSpecialArgs = {
    inherit inputs isLinux isDarwin;
    isDesktop = true;
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.sharedModules = [
    {stylix.enableReleaseChecks = false;}
  ];
  home-manager.users.brancengregory = {
    imports = [
      ../../users/brancengregory/home.nix
    ];
  };

  system.stateVersion = 5;
}

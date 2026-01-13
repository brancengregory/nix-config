{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/darwin.nix # Common MacOS settings
  ];

  home-manager.extraSpecialArgs = {inherit inputs;};
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.brancengregory = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
      ../../users/brancengregory/home.nix
    ];
  };

  system.stateVersion = 5;
}

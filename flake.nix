{
  description = "A flake for my NixOS configurations";

  inputs = {
    # NixOS official package source
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {

    nixosConfigurations = {
      powerhouse = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # Pass inputs to modules
        modules = [
          # 1. Import main config for this host
          ./hosts/powerhouse/configuration.nix

          # 2. Add Home Manager as a module to this system
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # 3. Import user specific Home Manager config
            home-manager.users.brancengregory = import ./users/brancengregory/home.nix;
          }
        ];
      };

      # Addition systems here
    };
  };
}

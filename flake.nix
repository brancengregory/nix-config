{
  description = "A flake for my NixOS configurations";

  inputs = {
    # NixOS official package sources

    # Stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Unstable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Darwin (Mac)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";

      # Make sure that nixpkgs.url and home-manager.url stay in sync and can work together
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations = {
      powerhouse = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;}; # Pass inputs to modules
        modules = [
          # 1. Import main config for this host
          ./hosts/powerhouse/config.nix

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

      # Additional NixOS systems here
    };

    darwinConfigurations = {
      turbine = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin"; # Intel CPU

        specialArgs = {inherit inputs;};

        modules = [
          ./hosts/turbine/config.nix

          # Add Home Manager support for MacOS
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.brancengregory = import ./users/brancengregory/home.nix;
          }
        ];
      };

      # Additional Mac systems here
    };

    # Create a VM for testing and cross-compilation targets
    packages.x86_64-linux = {
      powerhouse-vm = self.nixosConfigurations.powerhouse.config.system.build.vm;

      # Cross-compilation: Build darwin configs from Linux
      turbine-darwin = self.darwinConfigurations.turbine.system;

      # Validation: Check darwin configs without building
      turbine-check = self.darwinConfigurations.turbine.config.system.build.toplevel.drvPath;
    };

    # Enable cross-compilation for darwin packages on Linux
    packages.x86_64-darwin = {
      turbine-darwin = self.darwinConfigurations.turbine.system;
    };

    # Development shells for cross-platform work
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        nixos-rebuild
        nix-output-monitor
        alejandra # Nix formatter
        just # Command runner
      ];
      shellHook = ''
        echo "🚀 Cross-platform Nix development environment"
        echo "💡 Available commands:"
        echo "  - just build-darwin (cross-compile darwin config)"
        echo "  - just check-darwin (validate darwin config)"
        echo "  - just build-linux (build NixOS VM)"
        echo "  - just format (format Nix files)"
        echo "  - just help (show all commands)"
      '';
    };
  };
}

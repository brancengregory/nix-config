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

    # Plasma Manager
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    plasma-manager,
    ...
  } @ inputs: {
    nixosConfigurations = {
      powerhouse = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;}; # Pass inputs to modules
        modules = [
          {
            nixpkgs.overlays = [
              (final: prev: {
                radian = prev.python3Packages.radian.overridePythonAttrs (old: {
                  pyproject = true;
                  build-system = [final.python3Packages.setuptools];
                });
                rPackages =
                  prev.rPackages.override {
                    overrides = {
                      ojodb = prev.rPackages.buildRPackage {
                        name = "ojodb";
                        src = final.fetchFromGitHub {
                          owner = "openjusticeok";
                          repo = "ojodb";
                          rev = "v2.11.0";
                          sha256 = "sha256-skH4+WV31l2AKsurZOlzLLZLR0R8JGddJMLWAp65IYQ=";
                        };
                        propagatedBuildInputs = with final.rPackages; [
                          DBI
                          RPostgres
                          dplyr
                          dbplyr
                          ggplot2
                          pool
                          magrittr
                          rlang
                          stringr
                          purrr
                        ];
                      };
                    };
                  };
              })
            ];
          }
          home-manager.nixosModules.home-manager
          ./hosts/powerhouse/config.nix
        ];
      };

      # Additional NixOS systems here
    };

    darwinConfigurations = {
      turbine = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin"; # Intel CPU

        specialArgs = {inherit inputs;};

        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/turbine/config.nix
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
      turbine-check = self.darwinConfigurations.turbine.config.system.build.toplevel;
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
        mdbook # Documentation generator
      ];
      shellHook = ''
        echo "🚀 Cross-platform Nix development environment"
        echo "💡 Available commands:"
        echo "  - just build-darwin (cross-compile darwin config)"
        echo "  - just check-darwin (validate darwin config)"
        echo "  - just build-linux (build NixOS VM)"
        echo "  - just format (format Nix files)"
        echo "  - just docs-serve (serve documentation locally)"
        echo "  - just docs-build (build documentation)"
        echo "  - just help (show all commands)"
      '';
    };

    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };
  };
}

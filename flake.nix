{
  description = "A flake for my NixOS configurations";

  inputs = {
    # NixOS official package sources

    # Stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Darwin (Mac)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";

      # Make sure that nixpkgs.url and home-manager.url stay in sync and can work together
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Stylix for unified styling
    stylix.url = "github:danth/stylix";

    # Custom Neovim Configuration
    nvim-config = {
      url = "github:brancengregory/nvim";
      flake = false;
    };

    # Secret Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk Partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    plasma-manager,
    stylix,
    nvim-config,
    sops-nix,
    disko,
    ...
  } @ inputs: {
    nixosConfigurations = {
      powerhouse = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          isLinux = true;
          isDarwin = false;
        }; # Pass inputs to modules
        modules = [
          {
            nixpkgs.overlays = [
              (import ./overlays/ojodb.nix)
            ];
          }
          home-manager.nixosModules.home-manager
          inputs.stylix.nixosModules.stylix
          inputs.disko.nixosModules.disko
          ./hosts/powerhouse/config.nix
        ];
      };

      # Additional NixOS systems here
    };

    darwinConfigurations = {
      turbine = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin"; # Intel CPU

        specialArgs = {
          inherit inputs;
          isLinux = false;
          isDarwin = true;
        };

        modules = [
          {
            nixpkgs.overlays = [
              (import ./overlays/ojodb.nix)
            ];
          }
          home-manager.darwinModules.home-manager
          inputs.stylix.darwinModules.stylix
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

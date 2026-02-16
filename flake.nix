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
      
      # Cross-compile: Build NixOS VM from Darwin
      powerhouse-vm = self.nixosConfigurations.powerhouse.config.system.build.vm;
    };

    # Development shells for cross-platform work
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        # Nix ecosystem
        nixos-rebuild
        nix-output-monitor
        alejandra # Nix formatter
        mise # Universal task runner
        mdbook # Documentation generator
        
        # Secret management tools
        sops # Secrets management
        age # Modern encryption
        ssh-to-age # Convert SSH keys to age
        gnupg # GPG for key management
        pinentry-curses # GPG passphrase entry
        
        # WireGuard tools
        wireguard-tools
        
        # Cryptographic tools
        openssl # General crypto operations
        jq # JSON processing for scripts
        
        # System tools
        git # Version control
        usbutils # lsusb for hardware detection
        pciutils # lspci for hardware detection
        
        # Deployment helpers
        just # Task runner (alternative to mise)
        fzf # Fuzzy finder for interactive scripts
      ];
      
      shellHook = ''
        echo "🚀 Cross-platform Nix development environment"
        echo ""
        echo "🔐 Secret Generation & Management:"
        echo "  - ./scripts/generate-all-secrets.sh    # Generate all infrastructure secrets"
        echo "  - ./scripts/generate-host-secrets.sh   # Generate secrets for single host"
        echo "  - sops secrets/secrets.yaml            # Edit encrypted secrets"
        echo ""
        echo "💻 System Building & Deployment:"
        echo "  - mise build-darwin (cross-compile darwin config)"
        echo "  - mise check-darwin (validate darwin config)"
        echo "  - mise build-linux (build NixOS VM)"
        echo "  - nixos-install --flake .#powerhouse   # Install NixOS"
        echo ""
        echo "🛠️  Development Tools:"
        echo "  - mise format (format Nix files)"
        echo "  - mise docs-serve (serve documentation locally)"
        echo "  - mise docs-build (build documentation)"
        echo "  - mise help (show all commands)"
        echo ""
        echo "📚 Documentation:"
        echo "  - docs/MIGRATION.md       # Arch → NixOS migration guide"
        echo "  - docs/SECRET_MANAGEMENT.md # Secret workflow documentation"
        echo "  - docs/GPG-SSH-STRATEGY.md # Authentication strategy"
        echo ""
        
        # Set up environment for secret generation
        export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
        
        # Ensure scripts are executable
        chmod +x ./scripts/*.sh 2>/dev/null || true
        
        # Check for age key
        if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
          echo "⚠️  Warning: No age key found at $SOPS_AGE_KEY_FILE"
          echo "   Run: mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt"
          echo ""
        fi
      '';
    };

    devShells.x86_64-darwin.default = nixpkgs.legacyPackages.x86_64-darwin.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-darwin; [
        nix-output-monitor
        alejandra # Nix formatter
        mise # Universal task runner
        mdbook # Documentation generator
      ];
      shellHook = ''
        echo "🚀 Cross-platform Nix development environment"
        echo "💡 Available commands:"
        echo "  - mise build-darwin (build darwin config)"
        echo "  - mise check-darwin (validate darwin config)"
        echo "  - mise format (format Nix files)"
        echo "  - mise docs-serve (serve documentation locally)"
        echo "  - mise docs-build (build documentation)"
        echo "  - mise help (show all commands)"
      '';
    };

    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };
  };
}

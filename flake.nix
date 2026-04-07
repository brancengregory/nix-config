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

    # Stylix for unified styling (pin to release-25.11 to match Home Manager)
    stylix.url = "github:danth/stylix/release-25.11";

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

    # Nixvim - Nix-native Neovim configuration
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS Hardware - Framework laptop support
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    sops-nix,
    disko,
    ...
  } @ inputs: let
    lib = import ./lib {inherit inputs;};
  in {
    nixosConfigurations = {
      # DEPRECATED: powerhouse will become basestation after orbital is stable
      # powerhouse = lib.mkHost {
      #   hostname = "powerhouse";
      #   system = "x86_64-linux";
      #   user = "brancengregory";
      #   builder = nixpkgs.lib.nixosSystem;
      #   homeManagerModule = home-manager.nixosModules.home-manager;
      #   sopsModule = sops-nix.nixosModules.sops;
      #   isDesktop = true;
      #   extraModules = [
      #     inputs.disko.nixosModules.disko
      #   ];
      #   extraHomeModules = [
      #     inputs.plasma-manager.homeModules.plasma-manager
      #   ];
      # };

      orbital = lib.mkHost {
        hostname = "orbital";
        system = "x86_64-linux";
        user = "brancengregory";
        builder = nixpkgs.lib.nixosSystem;
        homeManagerModule = home-manager.nixosModules.home-manager;
        sopsModule = sops-nix.nixosModules.sops;
        isDesktop = false;
        extraModules = [
          inputs.disko.nixosModules.disko
        ];
      };

      # Framework 16 Laptop - AMD Ryzen AI 300 Series
      # Bootstrap config: no sops initially, add after age key generation
      voyager = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          isLinux = true;
          isDarwin = false;
          isDesktop = true;
        };
        modules = [
          # Core configuration
          ./hosts/voyager/config.nix
          ./hosts/voyager/hardware.nix
          ./hosts/voyager/disks.nix

          # Overlays
          {
            nixpkgs.overlays = [
              (import ./overlays/ojodb.nix)
            ];
          }

          # Framework 16 hardware support
          inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series

          # Disk partitioning
          inputs.disko.nixosModules.disko

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit inputs;
              isLinux = true;
              isDarwin = false;
              isDesktop = true;
            };
            home-manager.users.brancengregory = {
              imports = [
                ./users/brancengregory/home.nix
                inputs.plasma-manager.homeModules.plasma-manager
              ];
            };
          }

          # Stylix
          inputs.stylix.nixosModules.stylix
        ];
      };

      # ISO Installer configurations - kept as raw configs per scope discipline
      orbital-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          isLinux = true;
          isDarwin = false;
        };
        modules = [
          {
            nixpkgs.overlays = [
              (import ./overlays/ojodb.nix)
            ];
          }
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          inputs.sops-nix.nixosModules.sops
          inputs.disko.nixosModules.disko
          ./hosts/orbital/hardware.nix
          ./hosts/orbital/disks.nix
          {
            # ISO-specific settings
            isoImage.squashfsCompression = "zstd -Xcompression-level 3";

            # Basic system settings
            networking.hostName = "orbital-installer";
            time.timeZone = "America/Chicago";
            i18n.defaultLocale = "en_US.UTF-8";

            # Add tools needed for installation
            environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
              git
              vim
              curl
              wget
              gptfdisk
              cryptsetup
              btrfs-progs
              mergerfs
              snapraid
              disko
            ];

            # Enable SSH in the installer
            services.openssh = {
              enable = true;
              ports = [77];
              settings.PermitRootLogin = "yes";
            };

            # Boot loader for ISO
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Install tools
            programs.git.enable = true;
          }
        ];
      };

      # DEPRECATED: powerhouse will become basestation
      # powerhouse-iso = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   ...
      # };
    };

    # Darwin configurations - currently none active
    darwinConfigurations = {};

    # Create a VM for testing and cross-compilation targets
    packages.x86_64-linux = {
      # DEPRECATED: powerhouse-vm commented
      # powerhouse-vm = self.nixosConfigurations.powerhouse.config.system.build.vm;

      # Orbital system configuration
      orbital = self.nixosConfigurations.orbital.config.system.build.toplevel;

      # Framework 16 Laptop
      voyager = self.nixosConfigurations.voyager.config.system.build.toplevel;

      # ISO Installers
      orbital-iso = self.nixosConfigurations.orbital-iso.config.system.build.isoImage;
    };

    # Darwin packages - currently none active
    packages.x86_64-darwin = {};

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
        echo "🏠 Active Hosts:"
        echo "  - orbital     (NixOS homelab server - SOLO MODE)"
        echo "  - voyager     (Framework 16 Laptop - AMD Ryzen AI 300)"
        echo ""
        echo "🔨 Build Commands:"
        echo "  - mise build-orbital                 # Build orbital NixOS config"
        echo "  - mise build-orbital-iso             # Build orbital ISO installer"
        echo "  - mise build-voyager                 # Build voyager NixOS config"
        echo ""
        echo "✅ Validation Commands:"
        echo "  - mise check                         # Check flake syntax"
        echo "  - mise check-darwin                  # Validate macOS config"
        echo "  - mise dry-run-orbital               # Dry-run orbital config"
        echo "  - mise test                          # Run all validation tests"
        echo ""
        echo "🔐 Secret Management:"
        echo "  - mise secrets-edit                  # Edit encrypted secrets"
        echo "  - mise secrets-update-keys           # Update SOPS keys for all hosts"
        echo "  - mise secrets-generate              # Generate all infrastructure secrets"
        echo "  - sops secrets/secrets.yaml          # Direct edit with sops"
        echo ""
        echo "💻 Deployment:"
        echo "  - nixos-install --flake .#orbital    # Install NixOS orbital"
        echo "  - nixos-install --flake .#voyager    # Install NixOS voyager"
        echo ""
        echo "🛠️  Development Tools:"
        echo "  - mise format                        # Format Nix files"
        echo "  - mise dev                           # Enter development shell"
        echo "  - mise clean                         # Clean build results"
        echo "  - mise ssh-orbital                   # SSH into orbital"
        echo ""
        echo "📚 Documentation:"
        echo "  - mise docs-serve                    # Serve docs locally"
        echo "  - mise docs-build                    # Build documentation"
        echo "  - docs/MIGRATION.md                  # Arch → NixOS migration guide"
        echo "  - hosts/orbital/README.md            # Orbital server docs"
        echo "  - hosts/voyager/README.md            # Voyager laptop docs"
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

        echo "💡 Run 'mise help' or 'mise tasks' to see all available commands"
        echo ""
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

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

    # OpenCode - AI coding agent
    opencode-flake = {
      url = "github:aodhanhayter/opencode-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      powerhouse = lib.mkHost {
        hostname = "powerhouse";
        system = "x86_64-linux";
        user = "brancengregory";
        builder = nixpkgs.lib.nixosSystem;
        homeManagerModule = home-manager.nixosModules.home-manager;
        sopsModule = sops-nix.nixosModules.sops;
        isDesktop = true;
        extraModules = [
          inputs.disko.nixosModules.disko
        ];
        extraHomeModules = [
          inputs.plasma-manager.homeModules.plasma-manager
        ];
      };

      capacitor = lib.mkHost {
        hostname = "capacitor";
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

      # ISO Installer configurations - kept as raw configs per scope discipline
      capacitor-iso = nixpkgs.lib.nixosSystem {
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
          ./hosts/capacitor/hardware.nix
          ./hosts/capacitor/disks.nix
          {
            # ISO-specific settings
            isoImage.squashfsCompression = "zstd -Xcompression-level 3";

            # Basic system settings
            networking.hostName = "capacitor-installer";
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

            # Set a temporary root password for the installer
            # Note: Base ISO already sets initialHashedPassword = ""
            users.users.root.initialPassword = "nixos";

            # Boot loader for ISO
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Install tools
            programs.git.enable = true;
          }
        ];
      };

      powerhouse-iso = nixpkgs.lib.nixosSystem {
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
          ./hosts/powerhouse/hardware.nix
          ./hosts/powerhouse/disks/main.nix
          {
            # ISO-specific settings
            isoImage.squashfsCompression = "zstd -Xcompression-level 3";

            # Basic system settings
            networking.hostName = "powerhouse-installer";
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
              disko
            ];

            # Enable SSH in the installer
            services.openssh = {
              enable = true;
              ports = [22];
              settings.PermitRootLogin = "yes";
            };

            # Set a temporary root password for the installer
            # Note: Base ISO already sets initialHashedPassword = ""
            users.users.root.initialPassword = "nixos";

            # Boot loader for ISO
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Install tools
            programs.git.enable = true;
          }
        ];
      };
    };

    darwinConfigurations = {
      turbine = lib.mkHost {
        hostname = "turbine";
        system = "x86_64-darwin";
        user = "brancengregory";
        builder = nix-darwin.lib.darwinSystem;
        homeManagerModule = home-manager.darwinModules.home-manager;
        sopsModule = sops-nix.darwinModules.sops;
        isDesktop = true;
        extraModules = [];
      };
    };

    # Create a VM for testing and cross-compilation targets
    packages.x86_64-linux = {
      powerhouse-vm = self.nixosConfigurations.powerhouse.config.system.build.vm;

      # Capacitor system configuration
      capacitor = self.nixosConfigurations.capacitor.config.system.build.toplevel;
      powerhouse = self.nixosConfigurations.powerhouse.config.system.build.toplevel;

      # ISO Installers
      capacitor-iso = self.nixosConfigurations.capacitor-iso.config.system.build.isoImage;
      powerhouse-iso = self.nixosConfigurations.powerhouse-iso.config.system.build.isoImage;

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
        echo "🏠 Available Hosts:"
        echo "  - powerhouse  (NixOS desktop with dual-boot)"
        echo "  - capacitor   (NixOS homelab server)"
        echo "  - turbine     (macOS workstation)"
        echo ""
        echo "🔨 Build Commands:"
        echo "  - mise build-powerhouse              # Build powerhouse NixOS config"
        echo "  - mise build-powerhouse-iso          # Build powerhouse ISO installer"
        echo "  - mise build-capacitor               # Build capacitor NixOS config"
        echo "  - mise build-capacitor-iso           # Build capacitor ISO installer"
        echo "  - mise build-turbine                 # Build turbine macOS config"
        echo "  - mise build-all                     # Build all configurations"
        echo ""
        echo "✅ Validation Commands:"
        echo "  - mise check                         # Check flake syntax"
        echo "  - mise check-darwin                  # Validate macOS config"
        echo "  - mise dry-run-powerhouse            # Dry-run powerhouse config"
        echo "  - mise dry-run-capacitor             # Dry-run capacitor config"
        echo "  - mise test                          # Run all validation tests"
        echo ""
        echo "🔐 Secret Management:"
        echo "  - mise secrets-edit                  # Edit encrypted secrets"
        echo "  - mise secrets-update-keys           # Update SOPS keys for all hosts"
        echo "  - mise secrets-generate              # Generate all infrastructure secrets"
        echo "  - sops secrets/secrets.yaml          # Direct edit with sops"
        echo ""
        echo "💻 Deployment:"
        echo "  - nixos-install --flake .#powerhouse   # Install NixOS powerhouse"
        echo "  - nixos-install --flake .#capacitor    # Install NixOS capacitor"
        echo ""
        echo "🛠️  Development Tools:"
        echo "  - mise format                        # Format Nix files"
        echo "  - mise dev                           # Enter development shell"
        echo "  - mise clean                         # Clean build results"
        echo "  - mise ssh-capacitor                 # SSH into capacitor"
        echo "  - mise ssh-turbine                   # SSH into turbine"
        echo ""
        echo "📚 Documentation:"
        echo "  - mise docs-serve                    # Serve docs locally"
        echo "  - mise docs-build                    # Build documentation"
        echo "  - docs/MIGRATION.md                  # Arch → NixOS migration guide"
        echo "  - hosts/capacitor/README.md          # Capacitor server docs"
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

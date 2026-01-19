{
  pkgs,
  inputs,
  isLinux,
  isDarwin,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ../../modules/themes/stylix.nix
    ../../modules/hardware/nvidia.nix # NVIDIA GPU
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/plasma.nix
    ../../modules/media/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/monitoring.nix
    ../../modules/services/backup.nix
    ../../modules/network/wireguard.nix
    ../../modules/security/sops.nix
    ../../modules/virtualization/podman.nix
    ../../modules/virtualization/qemu.nix
  ];

  networking.hostName = "powerhouse";
  nixpkgs.config.allowUnfree = true;

  stylix.cursor = {
    package = pkgs.kdePackages.breeze;
    name = "Breeze_Snow";
    size = 24;
  };

  # Selectively enable targets that are safe and desired
  stylix.targets = {
    console.enable = true;
    gnome.enable = false;
    gtk.enable = true;
  };

  # Optimize VM Performance
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192; # 8GB RAM
      cores = 4;
      graphics = true;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };
    # Override Nvidia driver in VM to use standard QEMU graphics
    services.xserver.videoDrivers = pkgs.lib.mkForce ["modesetting"];
    hardware.nvidia.modesetting.enable = pkgs.lib.mkForce false;
    hardware.nvidia.open = pkgs.lib.mkForce false;

    # Force software rendering in VM to avoid kwin framebuffer errors
    environment.variables = {
      LIBGL_ALWAYS_SOFTWARE = "1";
      WLR_RENDERER = "pixman"; # For wlroots-based compositors (backup)
    };

    # Inject the persistent VM key so sops can decrypt secrets
    # Security Note: This puts the private key in the Nix store (world-readable on host)
    environment.etc."ssh/ssh_host_ed25519_key" = {
      source = "/home/brancengregory/code/brancengregory/nix-config/secrets/vm_host_key";
      mode = "0600";
    };

    # Share host sops keys with VM via QEMU 9p
    virtualisation.sharedDirectories = {
      sops_keys = {
        source = "/home/brancengregory/.config/sops";
        target = "/home/brancengregory/.config/sops";
      };
    };
  };

  home-manager.extraSpecialArgs = {
    inherit inputs isLinux isDarwin;
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [
    {stylix.enableReleaseChecks = false;}
  ];
  home-manager.users.brancengregory = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
      ../../users/brancengregory/home.nix
    ];
  };

  # Enable Snapper for Btrfs snapshots
  services.snapper.configs = {
    root = {
      SUBVOLUME = "/";
      ALLOW_USERS = ["brancengregory"];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
    };
  };

  system.stateVersion = "25.11";
}

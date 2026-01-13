{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ../../modules/hardware/nvidia.nix # NVIDIA GPU
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/plasma.nix
    ../../modules/media/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/monitoring.nix
    ../../modules/services/backup.nix
    ../../modules/network/wireguard.nix
  ];

  networking.hostName = "powerhouse";
  nixpkgs.config.allowUnfree = true;

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
  };

  home-manager.extraSpecialArgs = {inherit inputs;};
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
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

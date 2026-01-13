{pkgs, inputs, ...}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ../../modules/hardware/nvidia.nix # NVIDIA GPU
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/plasma.nix
    ../../modules/media/audio.nix
  ];

  networking.hostName = "powerhouse";
  nixpkgs.config.allowUnfree = true;

  # Optimize VM Performance
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192; # 8GB RAM
      cores = 4;
      graphics = true;
    };
    # Override Nvidia driver in VM to use standard QEMU graphics
    services.xserver.videoDrivers = pkgs.lib.mkForce [ "modesetting" ];
    hardware.nvidia.modesetting.enable = pkgs.lib.mkForce false;
    hardware.nvidia.open = pkgs.lib.mkForce false;
  };

  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.brancengregory = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
      ../../users/brancengregory/home.nix
    ];
  };

  system.stateVersion = "25.05";
}

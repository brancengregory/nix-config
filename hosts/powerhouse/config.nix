{pkgs, ...}: {
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

  home-manager.users.brancengregory = {
    imports = [
      ../../users/brancengregory/home.nix
    ];
  };

  system.stateVersion = "25.05";
}

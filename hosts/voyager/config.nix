# Framework 16 Laptop - AMD Ryzen AI 300 Series
# Bootstrap configuration - no sops initially
{
  config,
  pkgs,
  lib,
  inputs,
  isDesktop,
  ...
}: {
  imports = [
    # Common NixOS configuration
    ../../modules/os/common.nix
    ../../modules/os/nixos.nix

    # Desktop environment
    ../../modules/desktop

    # Hardware support
    ../../modules/hardware
  ];

  # Hostname
  networking.hostName = "voyager";

  # Enable Plasma desktop environment
  desktop.plasma.enable = true;
  desktop.sddm.enable = true;

  # System state version
  system.stateVersion = "25.11";

  # Boot configuration
  boot = {
    # Use systemd-boot
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # Kernel parameters for Framework 16
    # (most are handled by nixos-hardware framework-16-amd-ai-300-series module)
    kernelParams = [
      # Enable deep sleep for better battery life
      "mem_sleep_default=deep"
    ];
  };

  # Networking
  networking = {
    # Use NetworkManager for easy WiFi management (laptop)
    networkmanager.enable = true;
    
    # Disable systemd-networkd to avoid conflicts with NetworkManager
    useNetworkd = false;

    # Firewall - minimal for laptop
    firewall = {
      enable = true;
      # Allow SSH
      allowedTCPPorts = [22];
    };
  };

  # Services
  services = {
    # Enable power management
    power-profiles-daemon.enable = true;

    # Printing
    printing.enable = true;

    # Enable CUPS to print documents
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # Hardware - most handled by nixos-hardware module
  hardware = {
    # Bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  # User account configuration
  # Note: Base user account is defined in modules/os/nixos.nix
  # We extend it here with additional groups for laptop/desktop use
  users.users.brancengregory = {
    extraGroups = [
      "networkmanager"
      "video"
      "audio"
      "docker"
    ];
  };

  # Packages for the laptop
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    powertop
    tlp

    # Network
    networkmanagerapplet
    iw
    wirelesstools

    # Laptop specific
    brightnessctl
    fwupd
    framework-tool

    # Backup and sync (until properly configured)
    rsync
  ];

  # SSH daemon
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  # No declarative host keys - using nix-anywhere generated keys
  # After installation, extract SSH host key and generate age key

  # Disable sops initially - will be enabled after bootstrap
  # sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Note: Garbage collection is configured in modules/os/nixos.nix
  # Using default of 14 days there, can override if needed

  # Enable Docker (user is in docker group)
  virtualisation.docker.enable = true;
}

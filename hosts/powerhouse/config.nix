{
  config,
  pkgs,
  inputs,
  isLinux,
  isDarwin,
  isDesktop,
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
    ../../modules/network/wireguard.nix # WireGuard hub-and-spoke VPN
    ../../modules/security/sops.nix
    ../../modules/security/gpg.nix # Declarative GPG key import
    ../../modules/security/ssh.nix # Declarative SSH host keys
    ../../modules/virtualization/podman.nix
    ../../modules/virtualization/qemu.nix
    ./disks/main.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader - systemd-boot for UEFI with Windows dual-boot support
  boot.loader.systemd-boot = {
    enable = true;
    # Automatically detect Windows and other OSes
    extraEntries = {
      "windows.conf" = ''
        title Windows
        efi /EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
    # Allow editing boot entries during boot
    editor = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Mount Windows ESP for unified boot entries
  # This makes Windows bootloader accessible from systemd-boot menu
  fileSystems."/boot/efi-windows" = {
    device = "/dev/disk/by-partuuid/PARTUUID-OF-NVME0N1-ESP";
    fsType = "vfat";
    options = ["noauto" "x-systemd.automount"];
    # Note: Replace PARTUUID-OF-NVME0N1-ESP with actual partuuid after Windows install
    # Get it with: lsblk -o NAME,PARTUUID
  };

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

    # Provision sops key securely into the VM
    environment.etc."sops/age/keys.txt" = {
      source = "/home/brancengregory/.config/sops/age/keys.txt";
      mode = "0400";
      user = "brancengregory";
      group = "users";
    };

    system.activationScripts.sopsKeyHack = {
      text = ''
        mkdir -p /home/brancengregory/.config/sops/age
        ln -sf /etc/sops/age/keys.txt /home/brancengregory/.config/sops/age/keys.txt
        chown -R brancengregory:users /home/brancengregory/.config/sops
      '';
      deps = [];
    };
  };

  # Declarative WireGuard Configuration (Spoke - connects to Capacitor hub)
  networking.wireguard-mesh = {
    enable = true;
    nodeName = "powerhouse";
    hubNodeName = "capacitor";
    nodes = {
      capacitor = {
        ip = "10.0.0.1";
        publicKey = "psAKnDTfrEStGzrqCA3O9pvcz+AQc+gR0JpBOSh6tiE=";
        isServer = true;
        endpoint = "capacitor.yourdomain.com:51820";
      };
      powerhouse = {
        ip = "10.0.0.2";
        publicKey = "xsNOf2S+gjNralEsOAJbkHcslpHQ8fBsjD/OxWWLV2g=";
      };
      turbine = {
        ip = "10.0.0.3";
        publicKey = "QsnC5kPNXU/9WITRJEqW6RXMG1FpnwuYVixwCtLPeBU=";
      };
      battery = {
        ip = "10.0.0.4";
        publicKey = "avw08hoEMczOTsmsGIC89iMtw4s9/tbhRsSXUf+Ruxg=";
      };
    };
    privateKeyFile = config.sops.secrets."wireguard/powerhouse/private_key".path;
    presharedKeyFile = config.sops.secrets."wireguard/powerhouse/preshared_key".path;
  };

  # Declarative GPG Key Import
  security.gpg = {
    enable = true;
    user = "brancengregory";
    secretKeysFile = config.sops.secrets."gpg/powerhouse/secret_keys".path;
    publicKeysFile = config.sops.secrets."gpg/powerhouse/public_keys".path;
    trustLevel = 5;
    enableSSH = true;
  };

  # Declarative SSH Host Keys
  services.openssh.hostKeysDeclarative = {
    enable = true;
    ed25519 = {
      privateKeyFile = config.sops.secrets."ssh/powerhouse/host_key".path;
      publicKeyFile = config.sops.secrets."ssh/powerhouse/host_key_pub".path;
    };
  };

  # SOPS Secret Declarations
  # These will be populated by generate-all-secrets.sh
  sops.secrets = {
    # WireGuard secrets
    "wireguard/powerhouse/private_key" = {};
    "wireguard/powerhouse/preshared_key" = {};

    # GPG keys
    "gpg/powerhouse/secret_keys" = {};
    "gpg/powerhouse/public_keys" = {};

    # SSH host keys
    "ssh/powerhouse/host_key" = {};
    "ssh/powerhouse/host_key_pub" = {};
  };

  # Enable Snapper for Btrfs snapshots
  services.snapper.configs = {
    root = {
      SUBVOLUME = "/";
      ALLOW_USERS = ["brancengregory"];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 10;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 12;
      TIMELINE_LIMIT_YEARLY = 2;
    };
    home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = ["brancengregory"];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 5;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 6;
      TIMELINE_LIMIT_YEARLY = 1;
    };
  };

  # Enable Restic backup with host-specific configuration
  services.backup = {
    enable = true;
    repository = "gs:powerhouse-backup:/";
    paths = ["/home/brancengregory"];
    passwordFile = config.sops.secrets."restic/password".path;
    environmentFile = config.sops.secrets."restic/env".path;
  };

  system.stateVersion = "25.11";
}

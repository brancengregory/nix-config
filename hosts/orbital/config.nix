{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ./disks.nix # Disk configuration (preserves existing LUKS vaults)
    ../../modules/services # Bundle: all services
    ../../modules/network/wireguard.nix # WireGuard hub
    ../../modules/network/netbird.nix # Netbird self-hosted server
    ../../modules/network/caddy.nix # Caddy reverse proxy
    ../../modules/security/sops.nix
    ../../modules/security/gpg.nix # Hardware token support
    ../../modules/security/ssh.nix
    ../../modules/virtualization # Bundle: podman, qemu
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader - systemd-boot for UEFI
  boot.loader.systemd-boot = {
    enable = true;
    editor = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS Vault Drives - Unlock at boot with password
  # These preserve existing encrypted drives from Arch Linux setup
  boot.initrd.luks.devices = {
    # Vault 1 (sda) - 11TB
    crypt_vault1 = {
      device = "/dev/disk/by-uuid/a8f9df1c-f7f2-49ad-985c-6f5b7117ebac";
      allowDiscards = true;
    };
    # Vault 2 (sdb) - 11TB
    crypt_vault2 = {
      device = "/dev/disk/by-uuid/7e9cf71f-8db6-466a-b6de-757c7bc9baef";
      allowDiscards = true;
    };
    # Vault 3 (sdc) - 19TB (parity)
    crypt_vault3 = {
      device = "/dev/disk/by-uuid/de63d2dc-d155-4020-9897-f8328bdf9ede";
      allowDiscards = true;
    };
  };

  # Mount vault drives (preserved btrfs subvolumes)
  fileSystems = {
    "/mnt/vault1" = {
      device = "/dev/mapper/crypt_vault1";
      fsType = "btrfs";
      options = ["compress=zstd" "noatime" "nofail"];
    };
    "/mnt/vault2" = {
      device = "/dev/mapper/crypt_vault2";
      fsType = "btrfs";
      options = ["compress=zstd" "noatime" "nofail"];
    };
    "/mnt/vault3" = {
      device = "/dev/mapper/crypt_vault3";
      fsType = "btrfs";
      options = ["compress=zstd" "noatime" "nofail"];
    };
  };

  # SSH on port 77 (preserving current setup)
  services.openssh = {
    enable = true;
    ports = [77];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall - VPN-only access
  # Only WireGuard (51820/UDP) is exposed to WAN
  # All other services accessed via VPN (WireGuard 10.0.0.0/8 or NetBird 100.64.0.0/10)
  networking.firewall = {
    enable = true;
    # Only WireGuard port exposed to WAN
    allowedUDPPorts = [
      51820 # WireGuard
    ];
    # All TCP services are VPN-only (handled by extraCommands)
    allowedTCPPorts = [];
    # Allow VPN subnets to access all ports
    extraCommands = ''
      # Allow from WireGuard subnet (10.0.0.0/8)
      iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT

      # Allow from NetBird subnet (100.64.0.0/10)
      iptables -A INPUT -s 100.64.0.0/10 -j ACCEPT

      # Allow from localhost
      iptables -A INPUT -s 127.0.0.1 -j ACCEPT

      # Allow established connections
      iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # WireGuard Hub Configuration
  # NOTE: Currently solo mode - peers will be added when voyager/basestation are ready
  networking.wireguard-mesh = {
    enable = true;
    nodeName = "orbital";
    hubNodeName = "orbital";
    nodes = {
      orbital = {
        ip = "10.0.0.1";
        publicKey = "psAKnDTfrEStGzrqCA3O9pvcz+AQc+gR0JpBOSh6tiE=";
        isServer = true;
        # endpoint = "orbital.brancen.world:51820";  # TODO: Update with correct IP
      };
      # DEPRECATED: Will re-enable after voyager/basestation migration
      # powerhouse = {
      #   ip = "10.0.0.2";
      #   publicKey = "xsNOf2S+gjNralEsOAJbkHcslpHQ8fBsjD/OxWWLV2g=";
      # };
      # turbine = {
      #   ip = "10.0.0.3";
      #   publicKey = "QsnC5kPNXU/9WITRJEqW6RXMG1FpnwuYVixwCtLPeBU=";
      # };
      # battery = {
      #   ip = "10.0.0.4";
      #   publicKey = "avw08hoEMczOTsmsGIC89iMtw4s9/tbhRsSXUf+Ruxg=";
      # };
    };
    port = 51820;
    privateKeyFile = config.sops.secrets."wireguard/orbital/private_key".path;
  };

  # GPG hardware token support (disabled - server doesn't need user GPG)
  # Enable if needed: security.gpg.enable = true;

  # SSH host keys (server identity)
  services.openssh.hostKeysDeclarative = {
    enable = true;
    ed25519 = {
      privateKeyFile = config.sops.secrets."ssh/orbital/host_key".path;
      publicKeyFile = config.sops.secrets."ssh/orbital/host_key_pub".path;
    };
  };

  # Netbird Self-Hosted Configuration
  services.netbird-server = {
    enable = true;
    domain = "netbird.brancen.world";
    managementPort = 33073;
    dashboardPort = 18765;
    signalPort = 10000;
    turnPort = 3478;

    client = {
      enable = true;
      managementUrl = "https://netbird.brancen.world:33073";
    };

    secrets = {
      jwtSecretFile = config.sops.secrets."netbird/jwt-secret".path;
      adminPasswordHashFile = config.sops.secrets."netbird/admin-password-hash".path;
      postgresPasswordFile = config.sops.secrets."netbird/postgres-password".path;
      turnPasswordFile = config.sops.secrets."netbird/turn-password".path;
      encryptionKeyFile = config.sops.secrets."netbird/encryption-key".path;
    };
  };

  # OpenCode server
  services.opencode-server = {
    enable = true;
    port = 8081;
    workingDir = "/home/brancengregory/code";
    user = "brancengregory";
  };

  # Caddy Reverse Proxy with Wildcard SSL (uses DNS-01 challenge via Porkbun)
  services.caddy-proxy = {
    enable = false;
    domain = "brancen.world";
    porkbunCredentialsFile = config.sops.secrets."porkbun/credentials".path;

    services = {
      netbird = {
        subdomain = "netbird";
        port = 18765;
      };
      jellyfin = {
        subdomain = "jellyfin";
        port = 8096;
      };
      git = {
        subdomain = "git";
        port = 3080;
      };
      chat = {
        subdomain = "chat";
        port = 8080; # Open WebUI
      };
      grafana = {
        subdomain = "grafana";
        port = 3000;
      };
      prometheus = {
        subdomain = "prometheus";
        port = 9090;
      };
      downloads = {
        subdomain = "downloads";
        port = 8080; # qBittorrent
      };
      ollama = {
        subdomain = "ollama";
        port = 11434;
      };
      opencode = {
        subdomain = "opencode";
        port = 8081;
      };
    };
  };

  # SOPS Secret Declarations
  sops.secrets = {
    # WireGuard secrets
    "wireguard/orbital/private_key" = {};

    # Netbird secrets
    "netbird/jwt-secret" = {};
    "netbird/admin-password-hash" = {};
    "netbird/postgres-password" = {};
    "netbird/turn-password" = {};
    "netbird/encryption-key" = {};

    # Porkbun API credentials
    "porkbun/credentials" = {};

    # GPG keys - NOT NEEDED: Secret keys stored on Nitrokey hardware tokens
    # SSH host keys (server identity)
    "ssh/orbital/host_key" = {};
    "ssh/orbital/host_key_pub" = {};

    # Minio root credentials
    "minio/root_credentials" = {};
  };

  # Media group for shared access between arr apps and downloaders
  users.groups.media = {
    gid = 900;
  };

  # Ensure brancengregory is in media group for qBittorrent container access
  users.users.brancengregory.extraGroups = ["media"];

  # Enable media stack and download stack
  services.media = {
    enable = true;
    mediaDir = "/mnt/storage/standard/media";
  };

  services.download-stack = {
    enable = true;
    downloadDir = "/mnt/storage/ephemeral/downloads";
  };

  # Ensure storage directories exist with proper permissions
  systemd.tmpfiles.rules = [
    # Create base storage directories
    "d /mnt/storage 0755 root root -"
    "d /mnt/storage/standard 0755 root root -"
    "d /mnt/storage/ephemeral 0755 root root -"
    # Media and download directories will be created by their respective modules
  ];

  # Enable storage stack with mergerfs, SnapRAID, NFS, and Minio
  services.storage = {
    enable = true;
    mergerfs.enable = true;
    snapraid.enable = true;
    # NFS disabled for now - will re-enable when voyager/basestation are ready
    nfs = {
      enable = false;
      # exports = ''
      #   /mnt/storage/critical 10.0.0.0/8(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=1000,anongid=100)
      #   /mnt/storage/standard 10.0.0.0/8(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=1000,anongid=100)
      # '';
    };
    minio = {
      enable = true;
      dataDir = "/mnt/storage/standard/minio";
    };
  };

  # Ollama LLM server - models stored on NVMe for fast access
  services.ollama-server = {
    enable = true;
    acceleration = null; # CPU-only (no GPU on this server)
    modelsDir = "/var/lib/ollama"; # NVMe storage for fast model loading
  };

  # Forgejo Git server - repos on NVMe for fast git operations
  services.git-server = {
    enable = true;
    forgejo = {
      enable = true;
      domain = "git.brancen.world";
      httpPort = 3080;
      sshPort = 22; # Standard Git SSH port (system SSH moved to 77)
    };
    dataDir = "/var/lib/forgejo"; # NVMe storage for fast git operations
  };

  # System packages for server management
  environment.systemPackages = with pkgs; [
    mergerfs
    snapraid
    hdparm
    smartmontools
    nvme-cli
    mergerfs-tools
    netbird
  ];

  # Garbage collection - more aggressive for server
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = lib.mkForce "--delete-older-than 7d";
  };

  # Enable automatic Nix store optimization
  nix.settings.auto-optimise-store = true;

  # Monitoring (Orbital runs the full monitoring server stack)
  services.monitoring = {
    enable = true;
    exporters.enable = true; # Also run exporters on self
    exporters.collectors = ["systemd" "cpu" "memory" "disk" "filesystem" "loadavg"];
    server.enable = true; # Run heavy Prometheus/Grafana server here
    server.grafanaBind = "0.0.0.0"; # Bind to all interfaces for VPN access
  };

  # Virtualization (Capacitor runs containers, not VMs)
  virtualization.podman = {
    enable = true;
    dockerCompat = true;
    dnsEnabled = true;
  };

  virtualization.hypervisor.enable = false; # Server doesn't run VMs
  virtualization.guest.enable = false; # Not a VM

  # Ensure home-manager waits for sops-nix to provide secrets
  systemd.services.home-manager-brancengregory = {
    after = ["sops-nix.service"];
    requires = ["sops-nix.service"];
  };

  system.stateVersion = "25.11";
}

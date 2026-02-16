{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  isDarwin,
  ...
}: {
  imports = [
    ../../modules/os/common.nix # Universal settings
    ../../modules/os/nixos.nix # Common NixOS settings
    ./hardware.nix # Hardware-specific configuration
    ./disks.nix # Disk configuration (preserves existing LUKS vaults)
    ../../modules/themes/stylix.nix
    ../../modules/services/monitoring.nix
    ../../modules/services/media-stack.nix # Jellyfin, *arr apps
    ../../modules/services/download.nix # qBittorrent, SABnzbd
    ../../modules/services/ai.nix # Ollama, Open WebUI
    ../../modules/services/git.nix # Forgejo
    ../../modules/services/storage.nix # Minio, NFS, mergerfs, SnapRAID
    ../../modules/network/wireguard.nix # WireGuard hub
    ../../modules/network/netbird.nix # Netbird self-hosted server
    ../../modules/network/caddy.nix # Caddy reverse proxy
    ../../modules/security/sops.nix
    ../../modules/security/gpg.nix
    ../../modules/security/ssh.nix
    ../../modules/virtualization/podman.nix
  ];

  networking.hostName = "capacitor";
  nixpkgs.config.allowUnfree = true;

  # Bootloader - systemd-boot for UEFI
  boot.loader.systemd-boot = {
    enable = true;
    editor = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # SSH on port 77 (preserving current setup)
  services.openssh = {
    enable = true;
    ports = [77];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall - open necessary ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # Forgejo SSH
      77 # System SSH
      80 # HTTP
      443 # HTTPS
      3000 # Grafana
      3080 # Forgejo HTTP
      53 # DNS
      2049 # NFS
      111 # RPC (NFS)
      9090 # Prometheus
      9000 # Minio
      9001 # Minio console
      8000 # Ollama API
      8080 # Open WebUI
    ];
    allowedUDPPorts = [
      53 # DNS
      5353 # mDNS
      51820 # WireGuard
      111 # RPC (NFS)
      2049 # NFS
    ];
  };

  # WireGuard Hub Configuration
  networking.wireguard-mesh = {
    enable = true;
    nodeName = "capacitor";
    hubNodeName = "capacitor";
    nodes = {
      capacitor = {
        ip = "10.0.0.1";
        publicKey = "psAKnDTfrEStGzrqCA3O9pvcz+AQc+gR0JpBOSh6tiE=";
        isServer = true;
        endpoint = "192.168.1.167:51820";
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
    port = 51820;
    enableDnsServer = true;
    privateKeyFile = config.sops.secrets."wireguard/capacitor/private_key".path;
  };

  # Declarative GPG Key Import
  # NOTE: Generate GPG keys first before enabling this!
  # Run: gpg --full-generate-key on capacitor after install
  # Then add keys to secrets.yaml and re-enable
  # security.gpg = {
  #   enable = true;
  #   user = "brancengregory";
  #   secretKeysFile = config.sops.secrets."gpg/capacitor/secret_keys".path;
  #   publicKeysFile = config.sops.secrets."gpg/capacitor/public_keys".path;
  #   trustLevel = 5;
  #   enableSSH = true;
  # };

  # Declarative SSH Host Keys
  services.openssh.hostKeysDeclarative = {
    enable = true;
    ed25519 = {
      privateKeyFile = config.sops.secrets."ssh/capacitor/host_key".path;
      publicKeyFile = config.sops.secrets."ssh/capacitor/host_key_pub".path;
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
    };
  };

  # Caddy Reverse Proxy with Wildcard SSL (uses DNS-01 challenge via Porkbun)
  services.caddy-proxy = {
    enable = true;
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
    };
  };

  # SOPS Secret Declarations
  sops.secrets = {
    # WireGuard secrets
    "wireguard/capacitor/private_key" = {};

    # Netbird secrets
    "netbird/jwt-secret" = {};
    "netbird/admin-password-hash" = {};
    "netbird/postgres-password" = {};
    "netbird/turn-password" = {};
    
    # Porkbun API credentials
    "porkbun/credentials" = {};

    # GPG keys - Uncomment after generating keys
    # "gpg/capacitor/secret_keys" = {};
    # "gpg/capacitor/public_keys" = {};

    # SSH host keys
    "ssh/capacitor/host_key" = {};
    "ssh/capacitor/host_key_pub" = {};
  };

  # NFS Server exports
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/storage/critical 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
      /mnt/storage/standard 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
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
      ../../users/brancengregory/home-server.nix
    ];
  };

  system.stateVersion = "25.11";
}

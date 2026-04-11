{
  pkgs,
  lib,
  config,
  ...
}: {
  # --- Localization ---

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Shell ---
  programs.zsh.enable = true;

  # --- Flake Registry ---
  nix.registry = {
    # Your personal config - use string path to avoid pure eval issues
    nix-config.to = {
      type = "path";
      path = "/home/brancengregory/code/brancengregory/nix-config";
    };

    # Short names for nixpkgs
    stable.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-25.11";
    };

    unstable.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };

  # --- Networking ---

  # Default to networkd for servers, but allow hosts to override (e.g., for NetworkManager)
  networking.useNetworkd = lib.mkDefault true;

  # Enable systemd-networkd only when useNetworkd is true
  systemd.network.enable = lib.mkDefault config.networking.useNetworkd;

  # Using systemd-resolved for DNS (works with both networkd and NetworkManager)
  services.resolved.enable = true;

  # Using avahi for local network discovery (AirPla, Chromecast, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    reflector = true;
    publish = {
      enable = true;
      userServices = true;
      hinfo = true;
      domain = true;
      addresses = true;
    };
    extraServiceFiles = {};
    extraConfig = '''';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowedUDPPorts = [
      53
      5353
    ];
  };

  # --- User Account ---

  users.users.brancengregory = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    initialPassword = "password";
    # Password should be set during initial setup, not hardcoded
    # Use: sudo passwd brancengregory
  };

  # --- SSH ---
  services.openssh.enable = true;

  # --- Audio ---

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # --- Printing ---

  services.printing.enable = true;

  # --- Garbage Collector

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    iotop
    lsof
    usbutils
    pciutils
    dmidecode
    git
    google-chrome

    # Media/Video
    mpv
    obs-studio
    davinci-resolve
    zotero
  ];

  # --- Default Browser ---
  environment.variables = {
    BROWSER = "google-chrome-stable";
  };
}
